import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

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
    // Initial signed-in demo member for immediate exploration
    return AuthState(
      user: UserModel(
        id: 'usr_demo_01',
        email: 'alex@zubix.example',
        displayName: 'Alex Rivers',
        role: 'consumer',
      ),
    );
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600));

    if (email.trim().isEmpty || password.trim().isEmpty) {
      state = state.copyWith(isLoading: false, errorMessage: 'Please enter both email and password.');
      return;
    }

    final displayName = email.split('@').first;
    state = AuthState(
      user: UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: email.trim(),
        displayName: displayName[0].toUpperCase() + displayName.substring(1),
        role: 'consumer',
      ),
      isLoading: false,
    );
  }

  Future<void> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 700));

    if (email.trim().isEmpty || password.length < 6) {
      state = state.copyWith(isLoading: false, errorMessage: 'Password must be at least 6 characters.');
      return;
    }

    state = AuthState(
      user: UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: email.trim(),
        displayName: name.trim().isEmpty ? 'Zubix Member' : name.trim(),
        role: 'consumer',
      ),
      isLoading: false,
    );
  }

  void signOut() {
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
