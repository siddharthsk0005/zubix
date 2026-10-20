import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthState {
  final UserModel? user;
  final bool isInitializing;
  final bool isLoading;
  final String? errorMessage;
  final String? pendingPhone;
  // Dev builds only: the OTP code returned by the backend so it can be shown on screen.
  final String? devOtp;
  final bool needsProfileCompletion;
  // Set once when an admin approves a customer while the app is open (drives the approval notice).
  final bool justApproved;

  const AuthState({
    this.user,
    this.isInitializing = false,
    this.isLoading = false,
    this.errorMessage,
    this.devOtp,
    this.pendingPhone,
    this.needsProfileCompletion = false,
    this.justApproved = false,
  });

  bool get isAuthenticated =>
      user != null &&
      user!.isProfileComplete &&
      user!.approvalStatus == 'approved' &&
      !needsProfileCompletion;

  AuthState copyWith({
    UserModel? user,
    bool? isInitializing,
    bool? isLoading,
    String? errorMessage,
    String? pendingPhone,
    String? devOtp,
    bool? needsProfileCompletion,
    bool? justApproved,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      devOtp: devOtp ?? this.devOtp,
      needsProfileCompletion:
          needsProfileCompletion ?? this.needsProfileCompletion,
      justApproved: justApproved ?? this.justApproved,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() ProviderScope',
  );
});

class AuthNotifier extends Notifier<AuthState> {
  static const _storageKey = 'zubix_auth_user_v1';

  @override
  AuthState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final userJson = prefs.getString(_storageKey);
    if (userJson != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(map);
        if (user.isProfileComplete) {
          return AuthState(user: user, isInitializing: false);
        } else {
          return AuthState(
            user: user,
            isInitializing: false,
            needsProfileCompletion: true,
          );
        }
      } catch (_) {}
    }
    return const AuthState(isInitializing: false);
  }

  Future<void> _saveUserToStorage(UserModel user) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_storageKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _clearStorage() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  // Step 1: Send OTP for Mobile Number signup/login
  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final cleanPhone = phone.trim();
    if (cleanPhone.length < 7) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid mobile number.',
      );
      return false;
    }

    try {
      final result = await ApiService.sendOtp(cleanPhone);
      if (result != null && result['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          pendingPhone: cleanPhone,
          errorMessage: null,
          devOtp: result['devOtp']?.toString(),
        );
        return true;
      }
    } catch (_) {}

    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Could not send the verification code. Please try again.',
    );
    return false;
  }

  // Step 2: Verify OTP
  Future<bool> verifyOtp(String otp) async {
    final phone = state.pendingPhone;
    if (phone == null || phone.isEmpty) {
      state = state.copyWith(
        errorMessage: 'No pending mobile number. Please enter phone first.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    if (otp.trim().length != 4) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid 4-digit verification code.',
      );
      return false;
    }

    try {
      final result = await ApiService.verifyOtp(phone, otp.trim());
      if (result != null && result['user'] != null) {
        final user = result['user'] as UserModel;
        ApiService.setCustomerToken(result['token'] as String?);
        await _saveUserToStorage(user);
        state = AuthState(
          user: user,
          isLoading: false,
          needsProfileCompletion: !user.isProfileComplete,
          pendingPhone: user.isProfileComplete ? null : phone,
        );
        return true;
      }
    } catch (_) {}

    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Verification failed. Check the code and try again.',
    );
    return false;
  }

  // Social Login (Google / Apple)
  Future<bool> loginWithSocial(
    String provider, {
    String? email,
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await ApiService.socialLogin(
        provider,
        email: email,
        name: name,
      );
      if (result != null && result['user'] != null) {
        final user = result['user'] as UserModel;
        ApiService.setCustomerToken(result['token'] as String?);
        await _saveUserToStorage(user);
        state = AuthState(
          user: user,
          isLoading: false,
          needsProfileCompletion: !user.isProfileComplete,
          pendingPhone: user.isProfileComplete ? null : user.phone,
        );
        return true;
      }
    } catch (_) {}

    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Social sign-in failed. Please try again.',
    );
    return false;
  }

  // Step 3: Complete Onboarding Profile Details
  Future<bool> completeProfile({
    required String fullName,
    required String mobileNumber,
    required String country,
    required String userState,
    required String district,
  }) async {
    if (state.user == null) {
      state = state.copyWith(
        errorMessage: 'Authentication session expired. Please sign in again.',
      );
      return false;
    }

    if (fullName.trim().isEmpty ||
        mobileNumber.trim().isEmpty ||
        country.trim().isEmpty ||
        userState.trim().isEmpty ||
        district.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please fill in all profile fields to complete signup.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final updatedUser = await ApiService.completeProfile(
        userId: state.user!.id,
        name: fullName.trim(),
        phone: mobileNumber.trim(),
        country: country.trim(),
        state: userState.trim(),
        district: district.trim(),
      );

      if (updatedUser != null) {
        await _saveUserToStorage(updatedUser);
        state = AuthState(
          user: updatedUser,
          isLoading: false,
          needsProfileCompletion: false,
        );
        return true;
      }
    } catch (_) {}

    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Could not submit your profile. Please check your connection and try again.',
    );
    return false;
  }
  // Polls the backend for the customer's approval state and updates the saved session.
  Future<void> refreshApprovalStatus() async {
    final user = state.user;
    if (user == null || user.role != 'consumer') return;
    final status = await ApiService.getApprovalStatus(user.id);
    if (status == null || status == user.approvalStatus) return;

    final updated = user.copyWith(approvalStatus: status);
    await _saveUserToStorage(updated);
    state = state.copyWith(
      user: updated,
      justApproved: status == 'approved' ? true : state.justApproved,
    );
  }

  void acknowledgeApproval() {
    state = state.copyWith(justApproved: false);
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    if (email.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter your email.',
      );
      return false;
    }
    try {
      final user = await ApiService.login(
        email.trim(),
        name: email.split('@').first,
      );
      if (user != null) {
        await _saveUserToStorage(user);
        state = AuthState(user: user, isLoading: false);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    if (email.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter your email.',
      );
      return false;
    }
    try {
      final user = await ApiService.register(
        email.trim(),
        name: name.trim().isEmpty ? null : name.trim(),
      );
      if (user != null) {
        await _saveUserToStorage(user);
        state = AuthState(user: user, isLoading: false);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> signOut() async {
    ApiService.setCustomerToken(null);
    await _clearStorage();
    state = const AuthState(isInitializing: false);
  }

  // Saves edits to the signed-in customer's own profile. Throws with the backend message on failure.
  Future<void> updateProfile({
    required String name,
    required String? email,
    required String country,
    required String userState,
    required String district,
  }) async {
    final current = state.user;
    if (current == null) {
      throw Exception('Please sign in again to edit your profile.');
    }
    if (!ApiService.isCustomerSignedIn) {
      throw Exception(
        'Please sign out and sign in again once to enable profile editing.',
      );
    }
    final updated = await ApiService.updateCustomerProfile(
      name: name,
      email: email,
      country: country,
      state: userState,
      district: district,
    );
    if (updated == null) {
      throw Exception('Could not save your profile. Check your connection.');
    }
    await _saveUserToStorage(updated);
    state = state.copyWith(user: updated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
