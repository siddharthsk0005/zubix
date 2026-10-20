import 'package:flutter/material.dart';
import '../models/brand_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/swipable_gallery.dart';

class BrandPartnerDashboard extends StatefulWidget {
  final AppState state;

  const BrandPartnerDashboard({super.key, required this.state});

  @override
  State<BrandPartnerDashboard> createState() => _BrandPartnerDashboardState();
}

class _BrandPartnerDashboardState extends State<BrandPartnerDashboard> {
  late BrandModel _selectedBrand;
  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _bioController;
  late TextEditingController _websiteController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // Physical Store & Nearby Fields
  late bool _isPhysicalStore;
  late String _storeType;
  late TextEditingController _cityController;
  late TextEditingController _areaController;
  late TextEditingController _addressController;
  late TextEditingController _timingsController;
  late TextEditingController _mapsUrlController;

  // In-Store Counter Voucher Verification
  final TextEditingController _voucherVerifyController =
      TextEditingController();
  bool _isVerifyingVoucher = false;
  Map<String, dynamic>? _lastVerificationResult;

  @override
  void initState() {
    super.initState();
    // Default to first brand or first nearby store
    if (widget.state.brands.isNotEmpty) {
      _selectedBrand = widget.state.brands.first;
    } else if (widget.state.nearbyStores.isNotEmpty) {
      _selectedBrand = widget.state.nearbyStores.first;
    } else {
      _selectedBrand = BrandModel(
        id: 'brand_temp',
        name: 'Brand',
        tagline: '',
        bio: '',
        logoUrl: '',
        showcaseImages: [],
        websiteUrl: '',
        socialLinks: {},
        contactEmail: '',
        contactPhone: '',
        categoryId: '',
      );
    }
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _selectedBrand.name);
    _taglineController = TextEditingController(text: _selectedBrand.tagline);
    _bioController = TextEditingController(text: _selectedBrand.bio);
    _websiteController = TextEditingController(text: _selectedBrand.websiteUrl);
    _emailController = TextEditingController(text: _selectedBrand.contactEmail);
    _phoneController = TextEditingController(text: _selectedBrand.contactPhone);

    _isPhysicalStore = _selectedBrand.isPhysicalStore;
    _storeType = _selectedBrand.storeType;
    _cityController = TextEditingController(text: _selectedBrand.city ?? '');
    _areaController = TextEditingController(text: _selectedBrand.area ?? '');
    _addressController = TextEditingController(
      text: _selectedBrand.address ?? '',
    );
    _timingsController = TextEditingController(
      text: _selectedBrand.timings ?? '10:00 AM - 09:30 PM',
    );
    _mapsUrlController = TextEditingController(
      text: _selectedBrand.googleMapsUrl ?? '',
    );
    _lastVerificationResult = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _timingsController.dispose();
    _mapsUrlController.dispose();
    _voucherVerifyController.dispose();
    super.dispose();
  }

  Future<void> _handleCounterRedeem() async {
    final code = _voucherVerifyController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isVerifyingVoucher = true;
      _lastVerificationResult = null;
    });

    final res = await widget.state.verifyAndRedeemCounterVoucher(code);

    if (mounted) {
      setState(() {
        _isVerifyingVoucher = false;
        _lastVerificationResult = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine all brands and physical stores for dropdown
    final allBrands = <BrandModel>[
      ...widget.state.brands,
      ...widget.state.nearbyStores.where(
        (n) => !widget.state.brands.any((b) => b.id == n.id),
      ),
    ];

    final sessions = widget.state.sessions
        .where((s) => s.brandId == _selectedBrand.id)
        .toList();
    final totalClaims = sessions.fold<int>(
      0,
      (sum, s) => sum + s.claimedVouchersCount,
    );

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      appBar: AppBar(
        title: const Text('Brand Partner Portal'),
        actions: [
          DropdownButton<String>(
            value: allBrands.any((b) => b.id == _selectedBrand.id)
                ? _selectedBrand.id
                : allBrands.firstOrNull?.id,
            underline: const SizedBox.shrink(),
            items: allBrands.map((b) {
              return DropdownMenuItem(
                value: b.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      b.isPhysicalStore
                          ? Icons.storefront
                          : Icons.shopping_bag_outlined,
                      size: 14,
                      color: AppTheme.pureBlack,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      b.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (brandId) {
              if (brandId != null) {
                setState(() {
                  _selectedBrand = allBrands.firstWhere((b) => b.id == brandId);
                  _initControllers();
                });
              }
            },
          ),
          const SizedBox(width: 16),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status & Partner Header
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _selectedBrand.logoUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 52,
                          height: 52,
                          color: AppTheme.surfaceLight,
                          child: const Icon(
                            Icons.store,
                            color: AppTheme.pureBlack,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedBrand.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _isPhysicalStore
                                      ? AppTheme.pureBlack
                                      : AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _isPhysicalStore
                                      ? 'LOCAL BOUTIQUE / ATELIER'
                                      : 'ONLINE D2C BRAND',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: _isPhysicalStore
                                        ? AppTheme.pureWhite
                                        : AppTheme.pureBlack,
                                  ),
                                ),
                              ),
                              if (_isPhysicalStore &&
                                  _selectedBrand.city != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '📍 ${_selectedBrand.city}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedBrand.isApproved
                            ? AppTheme.pureBlack
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedBrand.isApproved
                            ? 'VERIFIED PARTNER'
                            : 'PENDING APPROVAL',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: _selectedBrand.isApproved
                              ? AppTheme.pureWhite
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Performance Analytics Grid
                const Text(
                  'BRAND PERFORMANCE METRICS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMetricCard(
                      'Generative Sessions',
                      '${sessions.length}',
                      Icons.bolt,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      'Vouchers Unlocked',
                      '$totalClaims',
                      Icons.card_giftcard,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      _isPhysicalStore ? 'Counter Footfall' : 'Store Clicks',
                      '${totalClaims * 9}',
                      _isPhysicalStore
                          ? Icons.directions_walk
                          : Icons.touch_app,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ----------------------------------------------------
                // IN-STORE COUNTER VOUCHER VERIFIER & SCANNER
                // ----------------------------------------------------
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.pureBlack,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: AppTheme.pureWhite,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PHYSICAL COUNTER VOUCHER TERMINAL',
                                  style: TextStyle(
                                    color: AppTheme.pureWhite,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  'Scan or enter consumer voucher code to redeem in-store',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                controller: _voucherVerifyController,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. ZUBIX-BRAND-30',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textTertiary,
                                    letterSpacing: 0.5,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _isVerifyingVoucher
                                ? null
                                : _handleCounterRedeem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.pureBlack,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isVerifyingVoucher
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.pureBlack,
                                    ),
                                  )
                                : const Text(
                                    'REDEEM CODE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (_lastVerificationResult != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _lastVerificationResult!['success'] == true
                                ? Colors.green.withValues(alpha: 0.2)
                                : (_lastVerificationResult!['alreadyRedeemed'] ==
                                          true
                                      ? Colors.amber.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _lastVerificationResult!['success'] == true
                                  ? Colors.green
                                  : (_lastVerificationResult!['alreadyRedeemed'] ==
                                            true
                                        ? Colors.amber
                                        : Colors.red),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _lastVerificationResult!['success'] == true
                                    ? Icons.check_circle
                                    : (_lastVerificationResult!['alreadyRedeemed'] ==
                                              true
                                          ? Icons.warning
                                          : Icons.error),
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _lastVerificationResult!['message'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Showcase Images Preview
                const Text(
                  'SWIPABLE LOOKBOOK SHOWCASE',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                SwipableGallery(
                  images: _selectedBrand.showcaseImages,
                  height: 220,
                  borderRadius: BorderRadius.circular(16),
                ),

                const SizedBox(height: 32),

                // ----------------------------------------------------
                // STORE TYPE & PHYSICAL BOUTIQUE CONFIGURATION
                // ----------------------------------------------------
                const Text(
                  'STORE ARCHITECTURE & LOCATION TYPE',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: AppTheme.pureBlack,
                        title: const Text(
                          'Feature in "Nearby" Local Boutiques',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Enables physical address, distance radar, and in-store drop participation',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        value: _isPhysicalStore,
                        onChanged: (val) {
                          setState(() {
                            _isPhysicalStore = val;
                            _storeType = val ? 'local_store' : 'online_d2c';
                          });
                        },
                      ),
                      if (_isPhysicalStore) ...[
                        const Divider(height: 24, color: AppTheme.borderLight),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                  hintText: 'e.g. Bengaluru, Mumbai, Jaipur',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _areaController,
                                decoration: const InputDecoration(
                                  labelText: 'Neighbourhood / District',
                                  hintText: 'e.g. Indiranagar, Bandra West',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Complete Store Address',
                            hintText: 'Street, Building, Landmark, Pin code',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _timingsController,
                                decoration: const InputDecoration(
                                  labelText: 'Operating Timings',
                                  hintText: 'e.g. 10:00 AM - 09:30 PM',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _mapsUrlController,
                                decoration: const InputDecoration(
                                  labelText: 'Google Maps Link',
                                  hintText: 'https://maps.google.com/?q=...',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Profile Edit Form
                const Text(
                  'BRAND IDENTITY & CONTACT INFORMATION',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Brand / Atelier Name',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _taglineController,
                  decoration: const InputDecoration(labelText: 'Tagline'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Atelier Story / Bio',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Official Website / Social URL',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Concierge Email',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Store Phone',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: () {
                    _selectedBrand.name = _nameController.text.trim();
                    _selectedBrand.tagline = _taglineController.text.trim();
                    _selectedBrand.bio = _bioController.text.trim();
                    _selectedBrand.websiteUrl = _websiteController.text.trim();
                    _selectedBrand.contactEmail = _emailController.text.trim();
                    _selectedBrand.contactPhone = _phoneController.text.trim();

                    _selectedBrand.isPhysicalStore = _isPhysicalStore;
                    _selectedBrand.storeType = _storeType;
                    _selectedBrand.city = _cityController.text.trim();
                    _selectedBrand.area = _areaController.text.trim();
                    _selectedBrand.address = _addressController.text.trim();
                    _selectedBrand.timings = _timingsController.text.trim();
                    _selectedBrand.googleMapsUrl = _mapsUrlController.text
                        .trim();

                    widget.state.updateBrand(_selectedBrand);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Atelier "${_selectedBrand.name}" settings updated & synced!',
                        ),
                        backgroundColor: AppTheme.pureBlack,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Save Partner Settings'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppTheme.pureBlack),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.pureBlack,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
