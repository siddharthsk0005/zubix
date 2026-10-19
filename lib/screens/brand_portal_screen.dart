import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/brand_registration_model.dart';
import '../models/session_request_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'brand_register_screen.dart';

/// /brands — Brand Portal
/// Unauthenticated: shows simple Gateway with [Login] and [Register] buttons
/// Authenticated: shows full Brand Dashboard
class BrandPortalScreen extends StatefulWidget {
  final AppState state;
  final String initialAuthView; // 'gateway' | 'login' | 'register'
  const BrandPortalScreen({
    super.key,
    required this.state,
    this.initialAuthView = 'gateway',
  });

  @override
  State<BrandPortalScreen> createState() => _BrandPortalScreenState();
}

class _BrandPortalScreenState extends State<BrandPortalScreen> {
  String _section = 'overview'; // overview | sessions | request | profile
  late String _authView; // 'gateway' | 'login' | 'register'

  final _portalEmailCtrl = TextEditingController();
  final _portalPassCtrl = TextEditingController();
  bool _obscurePortalPass = true;
  String? _portalLoginError;

  @override
  void initState() {
    super.initState();
    _authView = widget.initialAuthView;
  }

  @override
  void dispose() {
    _portalEmailCtrl.dispose();
    _portalPassCtrl.dispose();
    super.dispose();
  }

  // Resolved logged-in brand from AppState active session
  BrandRegistrationModel? get _brand => widget.state.currentBrandRegistration;

  bool get _hasApprovedBrand => _brand != null && _brand!.status == 'approved';

  @override
  Widget build(BuildContext context) {
    if (_brand == null) {
      return _buildBrandGatewayScaffold();
    }

    final isWide = MediaQuery.of(context).size.width > 860;
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSidebar(),
                      Expanded(child: _buildContent()),
                    ],
                  )
                : _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: isWide ? null : _buildMobileNav(),
    );
  }

  Widget _buildTopBar() {
    final allBrands = widget.state.brandRegistrations;

    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pushReplacementNamed('/'),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.pureBlack,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Center(child: Text('Z', style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white))),
                ),
                const SizedBox(width: 8),
                const Text('zubix', style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Brand Portal',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
          ),
          const SizedBox(width: 16),

          // Brand Switcher Dropdown (Allows switching to newly registered brand instantly!)
          if (allBrands.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                border: Border.all(color: AppTheme.borderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _brand?.id,
                  hint: const Text('Select Brand', style: TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.pureBlack),
                  items: allBrands.map((b) {
                    final isAppr = b.status == 'approved';
                    return DropdownMenuItem<String>(
                      value: b.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(b.brandName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isAppr ? Colors.green.shade50 : (b.status == 'rejected' ? Colors.red.shade50 : Colors.amber.shade50),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              b.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isAppr ? Colors.green.shade800 : (b.status == 'rejected' ? Colors.red.shade800 : Colors.amber.shade900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newId) {
                    if (newId != null) {
                      setState(() {
                        widget.state.currentBrandRegistrationId = newId;
                      });
                    }
                  },
                ),
              ),
            ),
          ],

          const Spacer(),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/brands/register'),
            icon: const Icon(Icons.add, size: 15),
            label: const Text('Register Another Brand', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              widget.state.currentBrandRegistrationId = null;
              setState(() {
                _portalLoginError = null;
                _authView = 'gateway';
              });
            },
            icon: const Icon(Icons.logout_rounded, size: 15, color: Color(0xFFDC2626)),
            label: const Text('Sign Out',
              style: TextStyle(fontSize: 12.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/admin'),
            child: const Text('Admin Panel →',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (_brand != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.pureBlack,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _brand!.brandName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_brand!.brandName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  _buildStatusBadge(_brand!.status),
                ],
              ),
            ),
          const Divider(),
          const SizedBox(height: 8),
          _buildNavItem('overview', Icons.grid_view_rounded, 'Overview'),
          _buildNavItem('sessions', Icons.flash_on_rounded, 'My Sessions'),
          _buildNavItem('request', Icons.add_circle_outline_rounded, 'Request Session'),
          _buildNavItem('profile', Icons.person_outline_rounded, 'Brand Profile'),
          const Spacer(),
          const Divider(),
            Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                widget.state.currentBrandRegistrationId = null;
                setState(() {
                  _portalLoginError = null;
                  _authView = 'gateway';
                });
              },
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Sign Out', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.borderLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String id, IconData icon, String label) {
    final selected = _section == id;
    return GestureDetector(
      onTap: () => setState(() => _section = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.pureBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
              color: selected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              color: selected ? Colors.white : AppTheme.textPrimary,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNav() {
    final items = [
      ('overview', Icons.grid_view_rounded, 'Overview'),
      ('sessions', Icons.flash_on_rounded, 'Sessions'),
      ('request', Icons.add_circle_outline_rounded, 'Request'),
      ('profile', Icons.person_outline_rounded, 'Profile'),
    ];
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: items.map((item) {
          final active = _section == item.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _section = item.$1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$2, size: 22,
                    color: active ? AppTheme.pureBlack : AppTheme.textTertiary),
                  const SizedBox(height: 3),
                  Text(item.$3, style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: active ? AppTheme.pureBlack : AppTheme.textTertiary)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(
        key: ValueKey(_section),
        child: switch (_section) {
          'overview' => _buildOverview(),
          'sessions' => _buildSessionsList(),
          'request' => _hasApprovedBrand
              ? _buildRequestSession()
              : _buildNotApprovedGate(),
          'profile' => _buildProfileSection(),
          _ => _buildOverview(),
        },
      ),
    );
  }

  Widget _buildBrandGatewayScaffold() {
    if (_authView == 'register') {
      return BrandRegisterScreen(
        state: widget.state,
        onBack: () => setState(() => _authView = 'gateway'),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _authView == 'login'
                  ? _buildGatewayLoginForm()
                  : _buildGatewayChoiceView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGatewayChoiceView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.pureBlack,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('Z',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            const Text('zubix',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('BRAND PARTNER PORTAL',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppTheme.textSecondary)),
        ),
        const SizedBox(height: 24),
        const Text(
          'Brand Gateway',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppTheme.pureBlack),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Select an option to access your dashboard or join as a brand partner.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Option 1: Login
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _authView = 'login';
                _portalLoginError = null;
              });
            },
            icon: const Icon(Icons.login_rounded, size: 20),
            label: const Text('Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pureBlack,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Option 2: Register
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _authView = 'register';
              });
            },
            icon: const Icon(Icons.app_registration_rounded, size: 20),
            label: const Text('Register',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.pureBlack,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.pureBlack, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Divider(color: Color(0xFFE5E7EB)),
        const SizedBox(height: 16),

        TextButton.icon(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          icon: const Icon(Icons.storefront_outlined, size: 16, color: AppTheme.textSecondary),
          label: const Text('Return to User App',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildGatewayLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _authView = 'gateway'),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18, color: AppTheme.textSecondary),
                    SizedBox(width: 4),
                    Text('Back',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Brand Login',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Brand Partner Login',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your registered email and password to access your dashboard.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 24),

        if (_portalLoginError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _portalLoginError!,
                    style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        const Text('Registered Work Email',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: _portalEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'partner@yourbrand.com',
            hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 14),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.pureBlack, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text('Password',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: _portalPassCtrl,
          obscureText: _obscurePortalPass,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 14),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.pureBlack, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePortalPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePortalPass = !_obscurePortalPass),
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _handlePortalLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pureBlack,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign In to Dashboard →',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _authView = 'register'),
            child: const Text('Don\'t have an account? Apply to Register →',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.pureBlack)),
          ),
        ),

        if (widget.state.brandRegistrations.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Registered Brands (Tap to sign in):',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          ...widget.state.brandRegistrations.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              onTap: () {
                _portalEmailCtrl.text = b.ownerEmail;
                _portalPassCtrl.text = b.password;
                _handlePortalLogin();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business_rounded, size: 15, color: AppTheme.pureBlack),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${b.brandName} (${b.ownerEmail})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: b.status == 'approved' ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(b.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: b.status == 'approved' ? Colors.green.shade800 : Colors.amber.shade900,
                        )),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ],
    );
  }

  void _handlePortalLogin() {
    final email = _portalEmailCtrl.text.trim();
    final pass = _portalPassCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _portalLoginError = 'Please enter both email and password.');
      return;
    }

    final success = widget.state.loginBrand(email, pass);
    if (success) {
      setState(() {
        _portalLoginError = null;
      });
    } else {
      setState(() {
        _portalLoginError = 'Invalid email or password. Verify your credentials or submit a brand registration.';
      });
    }
  }

  // ─── OVERVIEW ─────────────────────────────────────────────────────────────

  Widget _buildOverview() {
    final sessionRequests = widget.state.sessionRequests
        .where((s) => _brand != null && s.brandId == _brand!.id)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(
            _brand != null
                ? 'Welcome back, ${_brand!.ownerName.split(' ').first}!'
                : 'Register or log in to access your brand dashboard.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 28),
          // Status card
          if (_brand != null)
            _buildStatusCard(),
          const SizedBox(height: 20),
          // Quick stats
          if (_hasApprovedBrand) ...[
            _buildStatsRow(sessionRequests),
            const SizedBox(height: 24),
          ],
          // Quick actions
          _buildQuickActions(),
          const SizedBox(height: 24),
          // Recent session requests
          if (sessionRequests.isNotEmpty) ...[
            const Text('Recent Session Requests', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            ...sessionRequests.take(3).map((s) => _buildSessionRequestCard(s)),
          ],
          if (_brand == null) ...[
            const SizedBox(height: 20),
            _buildRegisterCta(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _brand!.status;
    final (color, bg, icon, msg) = switch (status) {
      'approved' => (const Color(0xFF16A34A), const Color(0xFFF0FDF4),
          Icons.verified_rounded, 'Your brand is approved and active on Zubix.'),
      'rejected' => (const Color(0xFFDC2626), const Color(0xFFFEF2F2),
          Icons.cancel_rounded, 'Application rejected: ${_brand!.rejectionReason ?? "See admin notes"}'),
      _ => (const Color(0xFFD97706), const Color(0xFFFFFBEB),
          Icons.hourglass_top_rounded, 'Your application is under review (1–2 business days).'),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status == 'approved' ? 'Account Active' :
                status == 'rejected' ? 'Application Rejected' : 'Under Review',
                style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
              const SizedBox(height: 2),
              Text(msg, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13)),
            ],
          )),
          if (status == 'rejected')
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/brands/register'),
              child: const Text('Reapply →', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<SessionRequestModel> requests) {
    final pending = requests.where((r) => r.status == 'pending_approval').length;
    final approved = requests.where((r) => r.status == 'approved').length;
    final live = requests.where((r) => r.status == 'brand_confirmed').length;

    return Row(
      children: [
        _buildStatCard('Total Requests', '${requests.length}', Icons.send_rounded, AppTheme.pureBlack),
        const SizedBox(width: 12),
        _buildStatCard('Pending', '$pending', Icons.schedule_rounded, const Color(0xFFD97706)),
        const SizedBox(width: 12),
        _buildStatCard('Live / Approved', '${approved + live}', Icons.flash_on_rounded, const Color(0xFF16A34A)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, color: color, letterSpacing: -1)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionChip('➕ Request a Session', () => setState(() => _section = 'request')),
        _buildActionChip('📋 View My Sessions', () => setState(() => _section = 'sessions')),
        _buildActionChip('✏️ Edit Profile', () => setState(() => _section = 'profile')),
      ],
    );
  }

  Widget _buildActionChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _buildRegisterCta() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.pureBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Join the Zubix Brand Network', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text('Register your brand to run generative sessions and connect with thousands of eager shoppers.',
            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/brands/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.pureBlack,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Register Your Brand →', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─── SESSIONS LIST ────────────────────────────────────────────────────────

  Widget _buildSessionsList() {
    final requests = widget.state.sessionRequests
        .where((s) => _brand != null && s.brandId == _brand!.id)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('My Sessions', style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
              if (_hasApprovedBrand)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _section = 'request'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Request', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pureBlack,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (requests.isEmpty)
            _buildEmptyState(
              '📋',
              'No session requests yet',
              _hasApprovedBrand
                  ? 'Submit your first session request to get started.'
                  : 'Your brand must be approved before requesting sessions.',
              _hasApprovedBrand ? () => setState(() => _section = 'request') : null,
              _hasApprovedBrand ? 'Request a Session' : null,
            )
          else
            ...requests.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSessionRequestCard(r, showActions: true),
            )),
        ],
      ),
    );
  }

  Widget _buildSessionRequestCard(SessionRequestModel req, {bool showActions = false}) {
    final (statusColor, statusBg, statusLabel) = switch (req.status) {
      'pending_approval' => (const Color(0xFFD97706), const Color(0xFFFFFBEB), '⏳ Pending Review'),
      'approved' => (const Color(0xFF16A34A), const Color(0xFFF0FDF4), '✅ Approved'),
      'rejected' => (const Color(0xFFDC2626), const Color(0xFFFEF2F2), '❌ Rejected'),
      'dates_proposed' => (const Color(0xFF7C3AED), const Color(0xFFF5F3FF), '📅 Dates Proposed'),
      'brand_confirmed' => (const Color(0xFF0284C7), const Color(0xFFF0F9FF), '🔵 Confirmed'),
      _ => (AppTheme.textSecondary, AppTheme.surfaceMuted, req.status),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${req.brandName} — Session Request',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel, style: TextStyle(
                  color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.calendar_today_rounded,
                _formatDate(req.effectiveDate)),
              const SizedBox(width: 10),
              _buildInfoChip(Icons.people_outline_rounded,
                '${req.totalSlots} total slots'),
              const SizedBox(width: 10),
              _buildInfoChip(Icons.local_offer_outlined,
                '${req.couponTiers.length} tier${req.couponTiers.length > 1 ? "s" : ""}'),
            ],
          ),
          // Coupon tiers
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: req.couponTiers.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${t.slots} × ${t.discountPct}% OFF',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
          // Proposed dates (if admin counter-proposed)
          if (req.status == 'dates_proposed' && req.proposedDates.isNotEmpty && showActions) ...[
            const SizedBox(height: 14),
            const Text('Admin proposed these alternate dates — pick one:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF7C3AED))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: req.proposedDates.map((d) => GestureDetector(
                onTap: () {
                  widget.state.brandConfirmSessionDate(req.id, d);
                  _showSnack('Date confirmed: ${_formatDate(d)}');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_formatDate(d), style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text('Submitted ${_timeAgo(req.submittedAt)}',
            style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  // ─── REQUEST SESSION ──────────────────────────────────────────────────────

  Widget _buildNotApprovedGate() {
    final isPending = _brand != null && _brand!.status == 'pending';
    final isRejected = _brand != null && _brand!.status == 'rejected';

    return Center(
      child: _buildEmptyState(
        isPending ? '⏳' : (isRejected ? '❌' : '🔒'),
        isPending
            ? 'Application Under Review'
            : (isRejected ? 'Application Rejected' : 'Brand not yet approved'),
        isPending
            ? '${_brand?.brandName ?? "Your brand"} is currently under review by the Zubix Admin team. You can approve it in the Admin Panel to unlock session creation.'
            : (isRejected
                ? 'Your registration was rejected: ${_brand?.rejectionReason ?? "Documentation incomplete"}. You can reapply with updated details.'
                : 'Your brand registration must be approved by admin before you can request sessions.'),
        isPending
            ? () => Navigator.of(context).pushReplacementNamed('/admin')
            : (isRejected
                ? () => Navigator.of(context).pushReplacementNamed('/brands/register')
                : () => Navigator.of(context).pushReplacementNamed('/brands/register')),
        isPending
            ? 'Open Admin Panel to Review →'
            : (isRejected ? 'Reapply Now' : 'Register Brand'),
      ),
    );
  }

  Widget _buildRequestSession() {
    return _RequestSessionForm(
      state: widget.state,
      brand: _brand!,
      onSubmitted: () {
        setState(() => _section = 'sessions');
        _showSnack('Session request submitted! Awaiting admin review.');
      },
    );
  }

  // ─── PROFILE ──────────────────────────────────────────────────────────────

  Widget _buildProfileSection() {
    if (_brand == null) {
      return Center(child: _buildEmptyState(
        '👤', 'No profile found', 'Register your brand first.',
        () => Navigator.of(context).pushReplacementNamed('/brands/register'), 'Register Now'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Brand Profile', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.pureBlack,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: Text(
                        _brand!.brandName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24))),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_brand!.brandName, style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 4),
                        _buildStatusBadge(_brand!.status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                ...[
                  ('Owner', _brand!.ownerName),
                  ('Email', _brand!.ownerEmail),
                  ('Phone', '+91 ${_brand!.ownerPhone}'),
                  ('Brand Type', _brand!.brandType == 'online_d2c' ? 'D2C / Online Brand' : 'Local Physical Store'),
                  if (_brand!.websiteUrl != null) ('Website', _brand!.websiteUrl!),
                  if (_brand!.instagramUrl != null) ('Instagram', _brand!.instagramUrl!),
                  if (_brand!.description != null) ('About', _brand!.description!),
                  if (_brand!.city != null) ('City', _brand!.city!),
                  if (_brand!.area != null) ('Area', _brand!.area!),
                  if (_brand!.address != null) ('Address', _brand!.address!),
                  if (_brand!.operatingHours != null) ('Hours', _brand!.operatingHours!),
                ].map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 100,
                        child: Text(row.$1, style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13))),
                      Expanded(child: Text(row.$2, style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Widget _buildStatusBadge(String status) {
    final (color, bg, label) = switch (status) {
      'approved' => (const Color(0xFF16A34A), const Color(0xFFDCFCE7), 'Approved'),
      'rejected' => (const Color(0xFFDC2626), const Color(0xFFFEE2E2), 'Rejected'),
      _ => (const Color(0xFFD97706), const Color(0xFFFEF3C7), 'Pending'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildEmptyState(
    String emoji,
    String title,
    String subtitle,
    VoidCallback? onAction,
    String? actionLabel,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pureBlack,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${_monthName(d.month)} ${d.day}, ${d.year}';

  String _monthName(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.pureBlack));
  }
}

// ─── REQUEST SESSION FORM ─────────────────────────────────────────────────────

class _RequestSessionForm extends StatefulWidget {
  final AppState state;
  final BrandRegistrationModel brand;
  final VoidCallback onSubmitted;

  const _RequestSessionForm({
    required this.state,
    required this.brand,
    required this.onSubmitted,
  });

  @override
  State<_RequestSessionForm> createState() => _RequestSessionFormState();
}

class _RequestSessionFormState extends State<_RequestSessionForm> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  final List<CouponTier> _tiers = [
    CouponTier(slots: 100, discountPct: 90),
    CouponTier(slots: 500, discountPct: 50),
    CouponTier(slots: 1000, discountPct: 20),
  ];
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _totalSlots => _tiers.fold(0, (s, t) => s + t.slots);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 3)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.pureBlack,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final req = SessionRequestModel(
      id: 'sreq_${DateTime.now().millisecondsSinceEpoch}',
      brandId: widget.brand.id,
      brandName: widget.brand.brandName,
      brandType: widget.brand.brandType,
      requestedDate: _selectedDate,
      couponTiers: List.from(_tiers),
      additionalNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    widget.state.submitSessionRequest(req);
    setState(() => _isSubmitting = false);
    widget.onSubmitted();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request a Generative Session', style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text('Set your preferred date and coupon tiers. Admin will review and confirm.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
            const SizedBox(height: 28),
            // Date picker
            _buildSectionTitle('📅 Preferred Session Date'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      '${_monthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const Spacer(),
                    const Text('Change', style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Coupon Tiers
            Row(
              children: [
                Expanded(child: _buildSectionTitle('🏷️ Coupon Tiers')),
                TextButton.icon(
                  onPressed: _tiers.length < 5 ? () {
                    setState(() => _tiers.add(CouponTier(slots: 200, discountPct: 15)));
                  } : null,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Tier', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Define tiers from highest to lowest discount. First-come, first-served — fastest users get the best deal.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 14),
            ..._tiers.asMap().entries.map((entry) =>
              _buildTierRow(entry.key, entry.value)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text('Total slots across all tiers: $_totalSlots',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('📝 Additional Notes (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Any special requirements, constraints, or message for the Zubix team...',
                hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.pureBlack, width: 1.5)),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: _isSubmitting
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.pureBlack,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Submitting...', style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: _tiers.isNotEmpty ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pureBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit Session Request ✓',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(int index, CouponTier tier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppTheme.pureBlack,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('${index + 1}', style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Slots', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                _buildNumberInput(
                  value: tier.slots,
                  onChanged: (v) => setState(() => _tiers[index].slots = v),
                  min: 1, max: 10000,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Discount %', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                _buildNumberInput(
                  value: tier.discountPct,
                  onChanged: (v) => setState(() => _tiers[index].discountPct = v),
                  min: 1, max: 99,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${tier.discountPct}% OFF', style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _tiers.length > 1 ? () => setState(() => _tiers.removeAt(index)) : null,
                child: Icon(Icons.remove_circle_outline_rounded,
                  size: 20,
                  color: _tiers.length > 1 ? const Color(0xFFDC2626) : AppTheme.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required int value,
    required void Function(int) onChanged,
    required int min,
    required int max,
  }) {
    final ctrl = TextEditingController(text: value.toString());
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      onChanged: (v) {
        final parsed = int.tryParse(v) ?? min;
        onChanged(parsed.clamp(min, max));
      },
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.pureBlack, width: 1.5)),
        filled: true,
        fillColor: AppTheme.surfaceLight,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15));
  }

  String _monthName(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];
}
