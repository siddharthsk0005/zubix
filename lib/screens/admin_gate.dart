import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'admin_screen.dart';

/// Guards the admin console behind email + password.
/// Admin accounts are created manually on the backend (`npm run create-admin`).
class AdminGate extends StatefulWidget {
  final AppState state;
  const AdminGate({super.key, required this.state});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAuthenticated = ApiService.isAdminSignedIn;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final ok = await ApiService.adminLogin(email, password);
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _isAuthenticated = ok;
      if (!ok) {
        _error = 'Invalid admin credentials, or the server is unreachable.';
      }
    });
    if (ok) _passwordController.clear();
  }

  void _signOut() {
    ApiService.adminSignOut();
    setState(() {
      _isAuthenticated = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return AdminScreen(state: widget.state, onSignOut: _signOut);
    }
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Admin Console',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in with your admin account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Password'),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
