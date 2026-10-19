import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/brand_registration_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// /brands/register — Public brand onboarding form.
/// Supports D2C Online Brands and Local Physical Stores.
class BrandRegisterScreen extends StatefulWidget {
  final AppState state;
  final bool initialIsLogin;
  final VoidCallback? onBack;
  const BrandRegisterScreen({super.key, required this.state, this.initialIsLogin = false, this.onBack});

  @override
  State<BrandRegisterScreen> createState() => _BrandRegisterScreenState();
}

class _BrandRegisterScreenState extends State<BrandRegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Mode: Register vs Login
  bool _isLoginMode = false;
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  bool _obscureLoginPassword = true;
  String? _loginError;

  // Step management (for registration)
  int _step = 0; // 0=Auth, 1=Brand Info, 2=Coupon Setup, 3=Review

  // Auth fields
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _otpVerified = false;

  // Brand info fields
  final _brandNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  // Local store fields
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController(text: '10:00 AM - 9:00 PM');

  String _brandType = 'online_d2c'; // or 'local_store'
  String _categoryId = 'cat_fashion';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<Map<String, String>> _categories = [
    {'id': 'cat_fashion', 'label': 'Fashion & Lifestyle'},
    {'id': 'cat_beauty', 'label': 'Beauty & Wellness'},
    {'id': 'cat_food', 'label': 'Food & Beverage'},
    {'id': 'cat_tech', 'label': 'Tech & Gadgets'},
    {'id': 'cat_home', 'label': 'Home & Décor'},
    {'id': 'cat_sports', 'label': 'Sports & Fitness'},
    {'id': 'cat_books', 'label': 'Books & Stationery'},
    {'id': 'cat_other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _isLoginMode = widget.initialIsLogin;
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _phoneCtrl.dispose(); _otpCtrl.dispose();
    _brandNameCtrl.dispose(); _ownerNameCtrl.dispose();
    _ownerEmailCtrl.dispose(); _passwordCtrl.dispose();
    _websiteCtrl.dispose(); _instagramCtrl.dispose();
    _descCtrl.dispose(); _cityCtrl.dispose(); _areaCtrl.dispose();
    _addressCtrl.dispose(); _hoursCtrl.dispose();
    super.dispose();
  }

  void _nextStep() => setState(() => _step = (_step + 1).clamp(0, 3));
  void _prevStep() => setState(() => _step = (_step - 1).clamp(0, 3));

  void _sendOtp() {
    if (_phoneCtrl.text.trim().length < 10) {
      _showSnack('Enter a valid 10-digit mobile number');
      return;
    }
    setState(() => _otpSent = true);
    _showSnack('OTP sent to +91 ${_phoneCtrl.text.trim()}');
  }

  void _verifyOtp() {
    if (_otpCtrl.text.trim().length < 4) {
      _showSnack('Enter the OTP received on your number');
      return;
    }
    setState(() { _otpVerified = true; _step = 1; });
    _showSnack('Phone verified successfully ✓');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.pureBlack),
    );
  }

  bool get _brandInfoStepValid =>
      _brandNameCtrl.text.trim().isNotEmpty &&
      _ownerNameCtrl.text.trim().isNotEmpty &&
      _ownerEmailCtrl.text.trim().isNotEmpty &&
      _passwordCtrl.text.trim().length >= 6 &&
      (_brandType == 'online_d2c' || _cityCtrl.text.trim().isNotEmpty);

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final reg = BrandRegistrationModel(
      id: 'reg_${DateTime.now().millisecondsSinceEpoch}',
      brandName: _brandNameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      ownerPhone: _phoneCtrl.text.trim(),
      ownerEmail: _ownerEmailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      brandType: _brandType,
      categoryId: _categoryId,
      websiteUrl: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
      instagramUrl: _instagramCtrl.text.trim().isEmpty ? null : _instagramCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      city: _brandType == 'local_store' ? _cityCtrl.text.trim() : null,
      area: _brandType == 'local_store' ? _areaCtrl.text.trim() : null,
      address: _brandType == 'local_store' ? _addressCtrl.text.trim() : null,
      operatingHours: _brandType == 'local_store' ? _hoursCtrl.text.trim() : null,
      status: 'pending',
    );

    widget.state.submitBrandRegistration(reg);
    setState(() => _isLoading = false);

    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.pureBlack,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Application Submitted!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(
                'Your brand registration is under review. You\'ll receive an email at ${_ownerEmailCtrl.text.trim()} once approved.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushReplacementNamed('/brands');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pureBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go to Brand Portal', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: Row(
        children: [
          // Left panel – branding
          if (MediaQuery.of(context).size.width > 800)
            Container(
              width: 340,
              color: AppTheme.pureBlack,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: widget.onBack ?? () => Navigator.of(context).pushReplacementNamed('/brands'),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('Z', style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Colors.black,
                                )),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('zubix',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                      Text(
                        _isLoginMode ? 'Welcome to\nBrand Portal.' : 'Grow your brand\nwith Zubix.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isLoginMode
                            ? 'Sign in to access your dashboard, monitor generative sessions, and configure brand voucher drops.'
                            : 'Join India\'s first generative coupon platform. Thousands of eager shoppers, zero wasted offers.',
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),
                      ..._buildFeaturePills(),
                      const Spacer(),
                      // Step progress / Security badge
                      if (_isLoginMode)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Secure brand partner login with end-to-end encryption.',
                                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildStepProgress(),
                    ],
                  ),
                ),
              ),
            ),
          // Right panel – form
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 800 ? 56 : 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mobile logo
                      if (MediaQuery.of(context).size.width <= 800) ...[
                        GestureDetector(
                          onTap: widget.onBack ?? () => Navigator.of(context).pushReplacementNamed('/brands'),
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
                        const SizedBox(height: 20),
                      ],

                      // Back to Options Button
                      InkWell(
                        onTap: widget.onBack ?? () => Navigator.of(context).pushReplacementNamed('/brands'),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 18, color: AppTheme.textSecondary),
                              SizedBox(width: 6),
                              Text('Back to Options',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mode Selector (Register vs Login)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() { _isLoginMode = false; _loginError = null; }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !_isLoginMode ? AppTheme.pureBlack : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text('Register Brand',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: !_isLoginMode ? Colors.white : AppTheme.textSecondary,
                                      )),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() { _isLoginMode = true; _loginError = null; }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isLoginMode ? AppTheme.pureBlack : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text('Brand Login',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _isLoginMode ? Colors.white : AppTheme.textSecondary,
                                      )),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (_isLoginMode)
                        _buildLoginForm()
                      else
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: [
                              _buildAuthStep(),
                              _buildBrandInfoStep(),
                              _buildReviewStep(),
                            ][_step.clamp(0, 2)],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeaturePills() {
    final features = [
      ('⚡', 'Live generative sessions'),
      ('🎯', 'Reach the right audience'),
      ('📊', 'Real-time analytics'),
      ('🏪', 'D2C & Local stores'),
    ];
    return features.map((f) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(f.$1, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(f.$2, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14)),
        ],
      ),
    )).toList();
  }

  Widget _buildStepProgress() {
    final steps = ['Verify', 'Details', 'Review'];
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i < _step;
        final active = i == _step;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                margin: EdgeInsets.only(right: i < steps.length - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  color: done || active ? Colors.white : const Color(0xFF444444),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              Text(steps[i], style: TextStyle(
                color: done || active ? Colors.white : const Color(0xFF666666),
                fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }),
    );
  }

  // ─── STEP 0: AUTH ─────────────────────────────────────────────────────────

  Widget _buildAuthStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Create your brand account', 'Start with your mobile number'),
        const SizedBox(height: 32),
        // Tab: Mobile / Google
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(
              color: AppTheme.pureBlack,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: '  📱  Mobile OTP  '),
              Tab(text: '  G  Google  '),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 240,
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // Mobile OTP
              _buildMobileOtpForm(),
              // Google
              _buildGoogleAuth(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Mobile Number'),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.borderLight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('+91', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _phoneCtrl,
                hint: '98765 43210',
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                enabled: !_otpVerified,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _otpVerified ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pureBlack,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                disabledBackgroundColor: AppTheme.borderLight,
              ),
              child: Text(_otpVerified ? '✓' : 'Send OTP',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
        if (_otpSent && !_otpVerified) ...[
          const SizedBox(height: 16),
          _buildLabel('Enter OTP'),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _otpCtrl,
                  hint: '• • • • • •',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pureBlack,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Enter the 4–6 digit verification code sent to your mobile',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
        ],
        if (_otpVerified) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              border: Border.all(color: const Color(0xFF86EFAC)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 16),
                const SizedBox(width: 8),
                Text('+91 ${_phoneCtrl.text} verified',
                  style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pureBlack,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue to Brand Details →',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGoogleAuth() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            setState(() { _otpVerified = true; _step = 1; });
            _showSnack('Signed in with Google');
          },
          icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
          label: const Text('Continue with Google',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 15)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            setState(() { _otpVerified = true; _step = 1; });
            _showSnack('Signed in with Facebook');
          },
          icon: const Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 22),
          label: const Text('Continue with Facebook',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 15)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }

  // ─── STEP 1: BRAND INFO ────────────────────────────────────────────────────

  Widget _buildBrandInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Tell us about your brand', 'Fill in your brand details'),
        const SizedBox(height: 24),
        // Brand Type Selector
        _buildLabel('Brand Type'),
        Row(
          children: [
            _buildTypeChip('online_d2c', '🌐  D2C / Online Brand',
              'Nationwide reach via Discover'),
            const SizedBox(width: 10),
            _buildTypeChip('local_store', '🏪  Local Physical Store',
              'Nearby geographic discovery'),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Brand Name *'),
                _buildTextField(controller: _brandNameCtrl, hint: 'e.g. Zephyr Apparel'),
              ],
            )),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Owner / Contact Name *'),
                _buildTextField(controller: _ownerNameCtrl, hint: 'Full name'),
              ],
            )),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Business Email *'),
                _buildTextField(controller: _ownerEmailCtrl,
                  hint: 'contact@yourbrand.com',
                  keyboardType: TextInputType.emailAddress),
              ],
            )),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Portal Password *'),
                _buildTextField(
                  controller: _passwordCtrl,
                  hint: '8+ characters',
                  obscureText: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                      size: 18, color: AppTheme.textTertiary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ],
            )),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabel('Category *'),
        _buildCategoryDropdown(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Website URL'),
                _buildTextField(controller: _websiteCtrl, hint: 'https://yourbrand.com'),
              ],
            )),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Instagram Handle'),
                _buildTextField(controller: _instagramCtrl, hint: '@yourbrand'),
              ],
            )),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabel('Brand Description'),
        _buildTextField(
          controller: _descCtrl,
          hint: 'Briefly describe your brand, products, and what makes you unique...',
          maxLines: 3,
        ),
        // Physical store fields
        if (_brandType == 'local_store') ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          _buildLabel('🏪 Store Location Details'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('City *'),
                  _buildTextField(controller: _cityCtrl, hint: 'e.g. Mumbai'),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Area / Locality'),
                  _buildTextField(controller: _areaCtrl, hint: 'e.g. Bandra West'),
                ],
              )),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabel('Full Store Address'),
          _buildTextField(controller: _addressCtrl, hint: '12 Street Name, Area, City - PIN'),
          const SizedBox(height: 16),
          _buildLabel('Operating Hours'),
          _buildTextField(controller: _hoursCtrl, hint: '10:00 AM - 9:00 PM'),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                side: const BorderSide(color: AppTheme.borderLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('← Back', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _brandInfoStepValid ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pureBlack,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: AppTheme.borderLight,
                ),
                child: const Text('Review & Submit →',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(String value, String label, String sub) {
    final selected = _brandType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _brandType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.pureBlack : Colors.white,
            border: Border.all(
              color: selected ? AppTheme.pureBlack : AppTheme.borderLight,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13,
                color: selected ? Colors.white : AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(
                fontSize: 11.5,
                color: selected ? const Color(0xFFAAAAAA) : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _categoryId,
          isExpanded: true,
          onChanged: (v) => setState(() => _categoryId = v!),
          items: _categories.map((c) => DropdownMenuItem(
            value: c['id'],
            child: Text(c['label']!, style: const TextStyle(fontSize: 14)),
          )).toList(),
        ),
      ),
    );
  }

  // ─── STEP 2: REVIEW ───────────────────────────────────────────────────────

  Widget _buildReviewStep() {
    final catLabel = _categories.firstWhere(
      (c) => c['id'] == _categoryId, orElse: () => {'label': _categoryId})['label']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Review your application', 'Everything correct? Submit to go live.'),
        const SizedBox(height: 24),
        _buildReviewCard('Brand Info', [
          ('Brand Name', _brandNameCtrl.text),
          ('Type', _brandType == 'online_d2c' ? 'D2C / Online Brand' : 'Local Physical Store'),
          ('Category', catLabel),
          ('Owner', _ownerNameCtrl.text),
          ('Phone', '+91 ${_phoneCtrl.text}'),
          ('Email', _ownerEmailCtrl.text),
          if (_websiteCtrl.text.isNotEmpty) ('Website', _websiteCtrl.text),
          if (_instagramCtrl.text.isNotEmpty) ('Instagram', _instagramCtrl.text),
        ]),
        if (_brandType == 'local_store') ...[
          const SizedBox(height: 16),
          _buildReviewCard('Store Details', [
            ('City', _cityCtrl.text),
            if (_areaCtrl.text.isNotEmpty) ('Area', _areaCtrl.text),
            if (_addressCtrl.text.isNotEmpty) ('Address', _addressCtrl.text),
            ('Hours', _hoursCtrl.text),
          ]),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            border: Border.all(color: const Color(0xFFFDE68A)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ℹ️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Your application will be reviewed by the Zubix team within 1–2 business days. You\'ll get an email with your dashboard credentials once approved.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                side: const BorderSide(color: AppTheme.borderLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('← Back', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _isLoading
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppTheme.pureBlack,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Submitting...', style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pureBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit Application ✓',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewCard(String title, List<(String, String)> rows) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(r.$1, style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13))),
                Expanded(child: Text(r.$2, style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Widget _buildStepHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step pills
        Row(
          children: List.generate(3, (i) {
            final done = i < _step;
            final active = i == _step;
            return Container(
              width: active ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: done || active ? AppTheme.pureBlack : AppTheme.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(
          fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(
        fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffix,
    int? maxLines,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        enabled: enabled,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 14),
          suffixIcon: suffix,
          filled: true,
          fillColor: enabled ? Colors.white : AppTheme.surfaceLight,
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
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
        ),
      ),
    );
  }

  // ─── BRAND LOGIN FORM ────────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Brand Partner Login',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in to manage your brand dashboard, schedule generative sessions, and view redemptions.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 28),

        if (_loginError != null) ...[
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
                    _loginError!,
                    style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        _buildLabel('Registered Work Email'),
        _buildTextField(
          controller: _loginEmailCtrl,
          hint: 'e.g. partner@yourbrand.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),

        _buildLabel('Password'),
        TextField(
          controller: _loginPasswordCtrl,
          obscureText: _obscureLoginPassword,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            ),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleBrandLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pureBlack,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign In to Brand Dashboard →',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),

        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () => setState(() { _isLoginMode = false; _loginError = null; }),
            child: const Text('Don\'t have an account? Apply to Register Brand →',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.pureBlack)),
          ),
        ),

        // Quick login helper if brands are already registered
        if (widget.state.brandRegistrations.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Registered Brands in System (Tap to Autofill):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          ...widget.state.brandRegistrations.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                _loginEmailCtrl.text = b.ownerEmail;
                _loginPasswordCtrl.text = b.password;
                _handleBrandLogin();
              },
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                side: const BorderSide(color: AppTheme.borderLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_rounded, size: 16, color: AppTheme.pureBlack),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${b.brandName} (${b.ownerEmail})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.pureBlack)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: b.status == 'approved' ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(b.status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                        color: b.status == 'approved' ? Colors.green.shade800 : Colors.amber.shade900)),
                  ),
                ],
              ),
            ),
          )),
        ],
      ],
    );
  }

  void _handleBrandLogin() {
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPasswordCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _loginError = 'Please enter both your email and password.');
      return;
    }

    final success = widget.state.loginBrand(email, pass);
    if (success) {
      Navigator.of(context).pushReplacementNamed('/brands');
    } else {
      setState(() {
        _loginError = 'Invalid email or password. Please verify your credentials or ensure your brand application is submitted.';
      });
    }
  }
}
