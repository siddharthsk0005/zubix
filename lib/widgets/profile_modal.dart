import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/vouchers_provider.dart';
import '../screens/admin_screen.dart';
import '../screens/brand_partner_dashboard.dart';
import '../screens/web_dashboard_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class ProfileModal extends ConsumerStatefulWidget {
  final AppState appState;

  const ProfileModal({super.key, required this.appState});

  static void show(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProfileModal(appState: appState),
    );
  }

  @override
  ConsumerState<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends ConsumerState<ProfileModal> {
  bool _isSignUp = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _secretTapCount = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSecretDevMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEVELOPER & PARTNER CONSOLE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
            const SizedBox(height: 6),
            const Text(
              'Internal access for store managers and platform administrators.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront_outlined, color: AppTheme.pureBlack),
              title: const Text('Brand Partner Portal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Nearby boutique settings & counter terminal', style: TextStyle(fontSize: 11.5)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BrandPartnerDashboard(state: widget.appState)),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.pureBlack),
              title: const Text('Admin Control Center', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Categories, sessions, and store approvals', style: TextStyle(fontSize: 11.5)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminScreen(state: widget.appState)),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.laptop_mac_outlined, color: AppTheme.pureBlack),
              title: const Text('Web Dashboard Portal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Desktop operations & analytics overview', style: TextStyle(fontSize: 11.5)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WebDashboardScreen(state: widget.appState)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final voucherCount = ref.watch(activeVouchersCountProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (authState.isAuthenticated && authState.user != null) ...[
              // ----------------------------------------------------
              // AUTHENTICATED CONSUMER PROFILE
              // ----------------------------------------------------
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: AppTheme.pureBlack,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        authState.user!.displayName.isNotEmpty
                            ? authState.user!.displayName.substring(0, 1).toUpperCase()
                            : 'Z',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.user!.displayName,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authState.user!.phone ?? authState.user!.email ?? '',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        if (authState.user!.district != null && authState.user!.state != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted),
                              const SizedBox(width: 2),
                              Text(
                                '${authState.user!.district}, ${authState.user!.state}',
                                style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: const Text(
                      'MEMBER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Wallet summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.pureBlack,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard, size: 20, color: AppTheme.pureWhite),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Voucher Wallet',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            voucherCount == 1 ? '1 Voucher ready to use' : '$voucherCount Vouchers ready to use',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Consumer Settings & Preferences
              const Text(
                'ACCOUNT & PREFERENCES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_none_outlined, color: AppTheme.pureBlack, size: 22),
                title: const Text('Generative Drop Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Get notified when nearby boutiques launch drops', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Drop alerts are enabled for your location.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.help_outline, color: AppTheme.pureBlack, size: 22),
                title: const Text('Help & Concierge Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Chat with our luxury shopping concierge', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Zubix Concierge: support@zubix.luxury'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shield_outlined, color: AppTheme.pureBlack, size: 22),
                title: const Text('Privacy & Terms', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Terms of service and merchant redemption rules', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {},
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(authProvider.notifier).signOut();
                  widget.appState.setCurrentUserId(null);
                },
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // ----------------------------------------------------
              // GUEST / SIGN IN / SIGN UP FORM
              // ----------------------------------------------------
              Text(
                _isSignUp ? 'Create Zubix Account' : 'Welcome to Zubix',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              const SizedBox(height: 4),
              Text(
                _isSignUp
                    ? 'Join to save vouchers across your devices and claim drops.'
                    : 'Sign in to access your personal voucher wallet.',
                style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
              ),

              const SizedBox(height: 20),

              if (authState.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),

              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        if (_isSignUp) {
                          final ok = await ref.read(authProvider.notifier).signUp(
                                _nameController.text,
                                _emailController.text,
                                _passwordController.text,
                              );
                          if (ok) {
                            final user = ref.read(authProvider).user;
                            if (user != null) {
                              widget.appState.setCurrentUserId(user.id);
                            }
                          }
                        } else {
                          final ok = await ref.read(authProvider.notifier).signIn(
                                _emailController.text,
                                _passwordController.text,
                              );
                          if (ok) {
                            final user = ref.read(authProvider).user;
                            if (user != null) {
                              widget.appState.setCurrentUserId(user.id);
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: authState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.pureWhite, strokeWidth: 2))
                    : Text(_isSignUp ? 'Create Account' : 'Sign In'),
              ),

              const SizedBox(height: 14),

              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() => _isSignUp = !_isSignUp);
                  },
                  child: Text(
                    _isSignUp ? 'Already have an account? Sign In' : 'New to Zubix? Create an Account',
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.pureBlack, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],

            // Discrete footer with hidden dev tap for internal testing
            Center(
              child: GestureDetector(
                onTap: () {
                  _secretTapCount++;
                  if (_secretTapCount >= 5) {
                    _secretTapCount = 0;
                    _showSecretDevMenu();
                  }
                },
                child: const Text(
                  'Zubix v1.0.0 • Pure Luxury Commerce',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
