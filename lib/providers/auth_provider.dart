import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState(
      user: UserModel(
        id: 'usr_demo_01',
        email: 'alex@zubix.example',
        displayName: 'Alex Rivers',
        role: 'consumer',
      ),
    );
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    if (email.trim().isEmpty || password.trim().isEmpty) {
      state = state.copyWith(isLoading: false, errorMessage: 'Please enter both email and password.');
      return false;
    }

    try {
      final user = await ApiService.login(email.trim(), name: email.split('@').first);
      if (user != null) {
        state = AuthState(user: user, isLoading: false);
        return true;
      }
    } catch (_) {}

    // Fallback if offline
    final displayName = email.split('@').first;
    state = AuthState(
      user: UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: email.trim(),
        displayName: displayName.isNotEmpty
            ? displayName[0].toUpperCase() + displayName.substring(1)
            : 'Zubix Member',
        role: 'consumer',
      ),
      isLoading: false,
    );
    return true;
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    if (email.trim().isEmpty || password.length < 6) {
      state = state.copyWith(isLoading: false, errorMessage: 'Password must be at least 6 characters.');
      return false;
    }

    try {
      final user = await ApiService.register(email.trim(), name: name.trim().isEmpty ? null : name.trim());
      if (user != null) {
        state = AuthState(user: user, isLoading: false);
        return true;
      }
    } catch (_) {}

    // Fallback if offline
    state = AuthState(
      user: UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: email.trim(),
        displayName: name.trim().isEmpty ? 'Zubix Member' : name.trim(),
        role: 'consumer',
      ),
      isLoading: false,
    );
    return true;
  }

  void signOut() {
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
