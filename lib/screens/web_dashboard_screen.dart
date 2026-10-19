import 'package:flutter/material.dart';
import '../models/brand_registration_model.dart';
import '../models/session_request_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'brand_portal_screen.dart';
import 'brand_register_screen.dart';

class WebDashboardScreen extends StatefulWidget {
  final AppState state;

  const WebDashboardScreen({super.key, required this.state});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  int _selectedSidebarIndex = 0; // 0: Overview, 1: Categories, 2: Sessions, 3: Partners, 4: Nearby Boutiques, 5: Counter Scanner

  // Counter scanner state
  final TextEditingController _voucherVerifyCtrl = TextEditingController();
  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult;

  @override
  void dispose() {
    _voucherVerifyCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCounterRedeem() async {
    final code = _voucherVerifyCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _verificationResult = null;
    });

    final res = await widget.state.verifyAndRedeemCounterVoucher(code);

    if (mounted) {
      setState(() {
        _isVerifying = false;
        _verificationResult = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: Row(
        children: [
          // 1. Sleek Monochrome Left Sidebar
          Container(
            width: 260,
            color: AppTheme.pureBlack,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ZUBIX',
                        style: TextStyle(
                          color: AppTheme.pureWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Control Center • Web',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Navigation Items
                _buildSidebarItem(0, 'Overview & Metrics', Icons.dashboard_outlined),
                _buildSidebarItem(1, 'Categories Manager', Icons.category_outlined),
                _buildSidebarItem(2, 'Generative Sessions', Icons.bolt_outlined),
                _buildSidebarItem(3, 'Partner Brands (D2C)', Icons.storefront_outlined),
                _buildSidebarItem(4, 'Nearby Boutiques & Shops', Icons.near_me_outlined),
                _buildSidebarItem(5, 'Counter Scanner Terminal', Icons.point_of_sale_outlined),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    'BRAND INGESTION & DROPS',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                _buildSidebarItem(6, 'Brand Registrations', Icons.app_registration_outlined,
                    badgeCount: widget.state.pendingRegistrations.length),
                _buildSidebarItem(7, 'Session Requests', Icons.campaign_outlined,
                    badgeCount: widget.state.pendingSessionRequests.length),

                const Spacer(),

                // Database Status Indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_done_outlined, size: 16, color: Colors.greenAccent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supabase PostgreSQL',
                              style: TextStyle(color: AppTheme.pureWhite, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Live & Synchronized',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Content Canvas
          Expanded(
            child: Container(
              color: AppTheme.surfaceLight,
              child: Column(
                children: [
                  // Top Canvas Bar
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    color: AppTheme.pureWhite,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getSectionTitle(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BrandRegisterScreen(state: widget.state),
                                    settings: const RouteSettings(name: '/brands/register'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.person_add_outlined, size: 16),
                              label: const Text('Brand Register (/brands/register)'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BrandPortalScreen(state: widget.state),
                                    settings: const RouteSettings(name: '/brands'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.storefront, size: 16),
                              label: const Text('Brand Portal (/brands)'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacementNamed(context, '/');
                                }
                              },
                              icon: const Icon(Icons.phone_iphone, size: 16),
                              label: const Text('Consumer App (/)'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Section Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: _buildSectionContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSectionTitle() {
    switch (_selectedSidebarIndex) {
      case 0:
        return 'Ecosystem Overview & Live Metrics';
      case 1:
        return 'Category Architecture & Taxonomy';
      case 2:
        return 'Generative Session Scheduling & Drops';
      case 3:
        return 'Partner Onboarding & Brand Verification';
      case 4:
        return 'Nearby Local Boutiques & Ateliers';
      case 5:
        return 'In-Store Counter Scanner & Voucher Terminal';
      case 6:
        return 'Brand Registration Applications (Onboarding Pipeline)';
      case 7:
        return 'Generative Session Requests & Date Negotiation';
      default:
        return '';
    }
  }

  Widget _buildSidebarItem(int index, String title, IconData icon, {int badgeCount = 0}) {
    final isSelected = _selectedSidebarIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selectedTileColor: AppTheme.accentDark,
        leading: Icon(icon, size: 18, color: isSelected ? AppTheme.pureWhite : AppTheme.textSecondary),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.pureWhite : AppTheme.textSecondary,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
        onTap: () => setState(() => _selectedSidebarIndex = index),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSidebarIndex) {
      case 0:
        return _buildOverviewSection();
      case 1:
        return _buildCategoriesSection();
      case 2:
        return _buildSessionsSection();
      case 3:
        return _buildPartnersSection();
      case 4:
        return _buildNearbyBoutiquesSection();
      case 5:
        return _buildCounterScannerSection();
      case 6:
        return _buildBrandRegistrationsSection();
      case 7:
        return _buildSessionRequestsSection();
      default:
        return const SizedBox.shrink();
    }
  }

  // ----------------------------------------------------
  // OVERVIEW SECTION
  // ----------------------------------------------------
  Widget _buildOverviewSection() {
    final totalBrands = widget.state.brands.length;
    final approvedBrands = widget.state.approvedBrands.length;
    final totalSessions = widget.state.sessions.length;
    final totalClaims = widget.state.sessions.fold<int>(0, (sum, s) => sum + s.claimedVouchersCount);
    final nearbyCount = widget.state.nearbyStores.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatCard('Ecosystem Brands', '$approvedBrands Approved', '$totalBrands registered', Icons.storefront),
            const SizedBox(width: 16),
            _buildStatCard('Generative Drops', '$totalSessions Active', 'Live on consumer app', Icons.bolt),
            const SizedBox(width: 16),
            _buildStatCard('Nearby Boutiques', '$nearbyCount Ateliers', 'Local physical stores', Icons.near_me),
            const SizedBox(width: 16),
            _buildStatCard('Vouchers Unlocked', '$totalClaims Claimed', 'Saved to user wallets', Icons.card_giftcard),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Active Generative Sessions Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ...widget.state.sessions.map((s) {
                final allBrands = [...widget.state.brands, ...widget.state.nearbyStores];
                final b = allBrands.firstWhere((br) => br.id == s.brandId, orElse: () => allBrands.first);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          b.logoUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.store),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                if (b.isPhysicalStore) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppTheme.pureBlack, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('LOCAL DROP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            Text('Session created by: ${s.sessionCreatedBy}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: BorderRadius.circular(8)),
                        child: Text('${s.waitingDurationSeconds}s countdown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 14),
                      Text(s.discountValue, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String mainValue, String subValue, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                Icon(icon, size: 20, color: AppTheme.pureBlack),
              ],
            ),
            const SizedBox(height: 12),
            Text(mainValue, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subValue, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // CATEGORIES SECTION
  // ----------------------------------------------------
  Widget _buildCategoriesSection() {
    final categories = widget.state.allCategories;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dynamic Category Architecture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ElevatedButton.icon(
                onPressed: () => _showAddCategoryDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Category'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.map((c) {
            final brandCount = widget.state.brands.where((b) => b.categoryId == c.id).length;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined, size: 20, color: AppTheme.pureBlack),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Slug: ${c.slug} • $brandCount brands linked', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: c.isActive,
                    activeTrackColor: AppTheme.pureBlack,
                    onChanged: (val) {
                      setState(() {
                        widget.state.updateCategory(c.id, c.name, isActive: val);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Fine Jewelry'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.state.addCategory(controller.text.trim());
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // SESSIONS SECTION
  // ----------------------------------------------------
  Widget _buildSessionsSection() {
    final sessions = widget.state.sessions;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Generative Session Builder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...sessions.map((s) {
            final allBrands = [...widget.state.brands, ...widget.state.nearbyStores];
            final b = allBrands.firstWhere((br) => br.id == s.brandId, orElse: () => allBrands.first);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      b.logoUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Session created by: ${s.sessionCreatedBy}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: BorderRadius.circular(8)),
                    child: Text('${s.waitingDurationSeconds}s countdown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 14),
                  Text(s.discountValue, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // PARTNERS SECTION
  // ----------------------------------------------------
  Widget _buildPartnersSection() {
    final brands = widget.state.brands;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ecosystem Brand Applications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...brands.map((b) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      b.logoUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(b.websiteUrl, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('Contact: ${b.contactEmail} • ${b.contactPhone}', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: b.isApproved,
                    activeTrackColor: AppTheme.pureBlack,
                    onChanged: (val) {
                      setState(() {
                        widget.state.approveBrand(b.id, val);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // NEARBY BOUTIQUES & LOCAL SHOPS SECTION
  // ----------------------------------------------------
  Widget _buildNearbyBoutiquesSection() {
    final nearby = widget.state.nearbyStores;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Local City Boutiques & Offline Ateliers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Physical stores featured in the consumer "Nearby" tab', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => widget.state.fetchNearbyStores(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Stores'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...nearby.map((store) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      store.logoUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.pureBlack, borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                '📍 ${store.city ?? "Local"}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(store.address ?? '${store.area}, ${store.city}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        Text('Hours: ${store.timings} • Contact: ${store.contactPhone}', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'DROP ACTIVE',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // COUNTER SCANNER & VOUCHER TERMINAL SECTION
  // ----------------------------------------------------
  Widget _buildCounterScannerSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('In-Store Counter Scanner & Voucher Terminal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Universal redemption terminal for cashiers and store staff at physical boutiques.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.pureBlack,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _voucherVerifyCtrl,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.5),
                          decoration: const InputDecoration(
                            hintText: 'Enter Voucher Code (e.g. ZUBIX-NOIR-30)',
                            hintStyle: TextStyle(fontSize: 14, color: AppTheme.textTertiary, letterSpacing: 0.5),
                            prefixIcon: Icon(Icons.qr_code_scanner, color: AppTheme.pureBlack),
                            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      onPressed: _isVerifying ? null : _handleCounterRedeem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.pureBlack,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isVerifying
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pureBlack))
                          : const Text('REDEEM CODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ],
                ),
                if (_verificationResult != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _verificationResult!['success'] == true
                          ? Colors.green.withValues(alpha: 0.2)
                          : (_verificationResult!['alreadyRedeemed'] == true
                              ? Colors.amber.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _verificationResult!['success'] == true
                            ? Colors.green
                            : (_verificationResult!['alreadyRedeemed'] == true ? Colors.amber : Colors.red),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _verificationResult!['success'] == true
                              ? Icons.check_circle
                              : (_verificationResult!['alreadyRedeemed'] == true ? Icons.warning : Icons.error),
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _verificationResult!['message'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // BRAND REGISTRATIONS SECTION (Web Desktop Admin)
  // ----------------------------------------------------
  Widget _buildBrandRegistrationsSection() {
    final regs = widget.state.brandRegistrations;
    final pendingCount = widget.state.pendingRegistrations.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Brand Onboarding Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                Text('$pendingCount pending review • ${regs.length} total applications',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BrandRegisterScreen(state: widget.state),
                    settings: const RouteSettings(name: '/brands/register'),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Open Brand Signup Form (/brands/register)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pureBlack,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (regs.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Text('No brand applications yet.',
                style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          )
        else
          ...regs.map((reg) => _buildWebRegCard(reg)),
      ],
    );
  }

  Widget _buildWebRegCard(BrandRegistrationModel reg) {
    final isPending = reg.status == 'pending';
    final isApproved = reg.status == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? const Color(0xFFDC2626).withValues(alpha: 0.4) : AppTheme.borderLight,
          width: isPending ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.pureBlack,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    reg.brandName.isNotEmpty ? reg.brandName[0].toUpperCase() : 'B',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
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
                        Text(reg.brandName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: reg.brandType == 'online_d2c' ? Colors.blue.shade50 : Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reg.brandType == 'online_d2c' ? 'ONLINE D2C' : 'LOCAL STORE / BOUTIQUE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: reg.brandType == 'online_d2c' ? Colors.blue.shade800 : Colors.purple.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Owner: ${reg.ownerName} • Phone: ${reg.ownerPhone} • Email: ${reg.ownerEmail}',
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? Colors.green.shade50
                      : (reg.status == 'rejected' ? Colors.red.shade50 : Colors.amber.shade50),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  reg.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isApproved
                        ? Colors.green.shade800
                        : (reg.status == 'rejected' ? Colors.red.shade800 : Colors.amber.shade900),
                  ),
                ),
              ),
            ],
          ),
          if (reg.description != null && reg.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(reg.description!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
          if (reg.address != null && reg.address!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('📍 Store Address: ${reg.address} • Hours: ${reg.operatingHours ?? "N/A"}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
          if (isApproved) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(
                '✓ Brand Authorized • Can login at /brands with email: ${reg.ownerEmail} & password set during registration',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade900),
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    widget.state.approveBrandRegistration(reg.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"${reg.brandName}" approved!'), backgroundColor: Colors.green),
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve & Onboard Brand'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pureBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    widget.state.rejectBrandRegistration(reg.id, 'Criteria not met');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Registration for "${reg.brandName}" declined.'), backgroundColor: Colors.red),
                    );
                  },
                  icon: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                  label: const Text('Reject', style: TextStyle(color: Color(0xFFDC2626))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // SESSION REQUESTS SECTION (Web Desktop Admin)
  // ----------------------------------------------------
  Widget _buildSessionRequestsSection() {
    final requests = widget.state.sessionRequests;
    final pendingCount = widget.state.pendingSessionRequests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Brand Generative Session Proposals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                Text('$pendingCount pending admin action • ${requests.length} total requests',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Text('No session requests submitted by brands yet.',
                style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          )
        else
          ...requests.map((req) => _buildWebSessionReqCard(req)),
      ],
    );
  }

  Widget _buildWebSessionReqCard(SessionRequestModel req) {
    final isPending = req.status == 'pending_approval';
    final isBrandConfirmed = req.status == 'brand_confirmed';
    final isApproved = req.status == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending || isBrandConfirmed ? AppTheme.pureBlack : AppTheme.borderLight,
          width: isPending || isBrandConfirmed ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppTheme.pureBlack, borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Icon(Icons.flash_on, color: Colors.white, size: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.brandName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text(
                      'Requested Live Date: ${req.requestedDate.day}/${req.requestedDate.month}/${req.requestedDate.year} • Total pool: ${req.totalSlots} vouchers',
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? Colors.green.shade50
                      : (req.status == 'dates_proposed' ? Colors.orange.shade50 : Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  req.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isApproved
                        ? Colors.green.shade800
                        : (req.status == 'dates_proposed' ? Colors.orange.shade800 : Colors.blue.shade800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text('Coupon Tiers Allocation:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: req.couponTiers
                .map((tier) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text('${tier.slots} shoppers get ${tier.discountPct}% OFF',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
          if (isPending || isBrandConfirmed) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    widget.state.approveSessionRequest(req.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Session for "${req.brandName}" is now LIVE!'), backgroundColor: Colors.green),
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(isBrandConfirmed ? 'Confirm Final & Launch' : 'Accept Date & Launch Live Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pureBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                if (isPending)
                  OutlinedButton.icon(
                    onPressed: () {
                      final alt1 = req.requestedDate.add(const Duration(days: 3));
                      final alt2 = req.requestedDate.add(const Duration(days: 7));
                      widget.state.proposeAlternateDates(req.id, [alt1, alt2]);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Proposed alternative dates sent to "${req.brandName}"!'),
                          backgroundColor: Colors.orange.shade800,
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('Propose Available Dates'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.pureBlack,
                      side: const BorderSide(color: AppTheme.pureBlack),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
