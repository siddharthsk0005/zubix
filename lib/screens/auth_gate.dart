import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'login_signup_screen.dart';
import 'approval_status_screen.dart';
import 'profile_onboarding_screen.dart';
import 'main_shell.dart';

class AuthGate extends ConsumerStatefulWidget {
  final AppState state;

  const AuthGate({super.key, required this.state});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 1. Initializing / Reading stored session
    if (authState.isInitializing) {
      return Scaffold(
        backgroundColor: AppTheme.pureWhite,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.pureBlack,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Z',
                    style: TextStyle(
                      color: AppTheme.pureWhite,
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ZUBIX',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: AppTheme.pureBlack,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppTheme.pureBlack,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Unauthenticated: Profile Onboarding needed
    if (authState.needsProfileCompletion) {
      return ProfileOnboardingScreen(appState: widget.state);
    }

    // 3. Profile submitted, waiting for admin approval (or rejected)
    if (authState.user != null &&
        authState.user!.role == 'consumer' &&
        authState.user!.isProfileComplete &&
        authState.user!.approvalStatus != 'approved') {
      return const ApprovalStatusScreen();
    }

    // 4. Unauthenticated: Not logged in
    if (!authState.isAuthenticated) {
      return const LoginSignupScreen();
    }

    // 5. Authenticated & Profile Completed: Main App
    if (widget.state.currentUserId != authState.user?.id && authState.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.state.setCurrentUserId(authState.user!.id);
      });
    }

    if (authState.justApproved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !ref.read(authProvider).justApproved) return;
        ref.read(authProvider.notifier).acknowledgeApproval();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your Zubix account has been approved. Welcome!'),
          ),
        );
      });
    }

    return MainShell(state: widget.state);
  }
}
