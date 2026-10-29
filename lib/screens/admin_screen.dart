import 'package:flutter/material.dart';
import '../models/brand_model.dart';
import '../models/brand_registration_model.dart';
import '../models/social_channel.dart';
import '../models/session_model.dart';
import '../models/session_request_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_customers_panel.dart';
import '../widgets/brand_profile_edit_dialog.dart';
import '../widgets/session_pool_dialog.dart';

class AdminScreen extends StatefulWidget {
  final AppState state;

  final VoidCallback? onSignOut;
  const AdminScreen({super.key, required this.state, this.onSignOut});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter for Brands Tab
  String _brandFilter = 'all'; // 'all', 'online', 'physical'

  // Counter Scanner Terminal
  final TextEditingController _adminVoucherController = TextEditingController();
  bool _isVerifyingVoucher = false;
  Map<String, dynamic>? _verificationResult;

  // Filters for New Tabs
  String _regFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'
  String _sessionReqFilter =
      'all'; // 'all', 'pending_approval', 'dates_proposed', 'brand_confirmed', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    widget.state.loadAdminQueues();
  }

  // Shows the real outcome of a server-backed admin action.
  Future<void> _runAdminAction(
    Future<bool> action,
    String successMessage,
    Color successColor,
  ) async {
    final ok = await action;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? successMessage
              : 'Action failed. Check the server connection and admin sign-in.',
        ),
        backgroundColor: ok ? successColor : Colors.red.shade700,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _adminVoucherController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // ADD / EDIT CATEGORY DIALOG
  // ----------------------------------------------------
  void _showCategoryDialog({
    String? categoryId,
    String? currentName,
    String currentScope = 'brand',
  }) {
    final textController = TextEditingController(text: currentName ?? '');
    var scope = currentScope;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          categoryId == null ? 'Add New Category' : 'Edit Category',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Changes will immediately update the consumer app navigation.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Luxury Footwear, Organic Snacks',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: scope,
                decoration: const InputDecoration(labelText: 'Used in'),
                items: const [
                  DropdownMenuItem(
                    value: 'brand',
                    child: Text('Brands tab & brand registration'),
                  ),
                  DropdownMenuItem(
                    value: 'nearby',
                    child: Text('Nearby tab (local stores)'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => scope = v);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                if (categoryId == null) {
                  widget.state.addCategory(name, scope: scope);
                } else {
                  widget.state.updateCategory(categoryId, name, scope: scope);
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category "$name" saved!'),
                    backgroundColor: AppTheme.pureBlack,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save Category'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // CREATE GENERATIVE SESSION DIALOG (Online & In-Store)
  // ----------------------------------------------------
  void _showCreateSessionDialog() {
    final allBrands = <BrandModel>[
      ...widget.state.brands,
      ...widget.state.nearbyStores.where(
        (n) => !widget.state.brands.any((b) => b.id == n.id),
      ),
    ];

    if (allBrands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one partner brand first.'),
        ),
      );
      return;
    }

    String selectedBrandId = allBrands.first.id;
    bool isInStoreDrop = allBrands.first.isPhysicalStore;
    final createdByController = TextEditingController(text: 'Admin Curators');
    final discountController = TextEditingController(
      text: isInStoreDrop ? '30% FLAT IN-STORE' : '30% FLAT OFF',
    );
    final couponController = TextEditingController(
      text: isInStoreDrop ? 'ZUBIX-LOCAL-30' : 'ZUBIX-DROP-30',
    );
    int waitingSeconds = 15;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.pureWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Create Generative Session',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Featured Brand / Atelier',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBrandId,
                    items: allBrands.map((b) {
                      return DropdownMenuItem(
                        value: b.id,
                        child: Text(
                          '${b.name}${b.isPhysicalStore ? " (📍 ${b.city ?? 'Local'})" : ""}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedBrandId = val;
                          final b = allBrands.firstWhere((br) => br.id == val);
                          isInStoreDrop = b.isPhysicalStore;
                          if (isInStoreDrop) {
                            discountController.text = '30% FLAT IN-STORE';
                            couponController.text =
                                'ZUBIX-LOCAL-${b.name.substring(0, b.name.length >= 4 ? 4 : b.name.length).toUpperCase()}';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // In-Store Drop Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeTrackColor: AppTheme.pureBlack,
                      title: const Text(
                        'In-Store Physical Drop',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: const Text(
                        'Generates in-store counter barcode/QR for redemption',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      value: isInStoreDrop,
                      onChanged: (val) {
                        setDialogState(() {
                          isInStoreDrop = val;
                          if (val) {
                            discountController.text = '30% FLAT IN-STORE';
                          } else {
                            discountController.text = '30% FLAT OFF';
                          }
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 14),
                  TextField(
                    controller: createdByController,
                    decoration: const InputDecoration(
                      labelText: 'Session Created By',
                      hintText: 'Person or Company name assigned by Admin',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Waiting Duration: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${waitingSeconds}s',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: waitingSeconds.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    activeColor: AppTheme.pureBlack,
                    inactiveColor: AppTheme.borderLight,
                    onChanged: (v) =>
                        setDialogState(() => waitingSeconds = v.round()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: discountController,
                    decoration: const InputDecoration(
                      labelText: 'Discount Reward Value',
                      hintText: 'e.g. 30% FLAT IN-STORE or 25% OFF',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: couponController,
                    decoration: const InputDecoration(
                      labelText: 'Coupon Code Template',
                      hintText: 'e.g. ZUBIX-LOCAL-30',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final newSession = SessionModel(
                    id: 'session_${DateTime.now().millisecondsSinceEpoch}',
                    title: isInStoreDrop
                        ? 'In-Store Exclusive Drop'
                        : 'Generative Drop Session',
                    brandId: selectedBrandId,
                    sessionCreatedBy: createdByController.text.trim().isEmpty
                        ? 'Admin Team'
                        : createdByController.text.trim(),
                    waitingDurationSeconds: waitingSeconds,
                    discountValue: discountController.text.trim(),
                    couponCode: couponController.text.trim().toUpperCase(),
                    status: 'active',
                  );
                  widget.state.addSession(newSession);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Generative Session created & published live!',
                      ),
                      backgroundColor: AppTheme.pureBlack,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Publish Session'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // EDIT PHYSICAL BOUTIQUE LOCATION DIALOG
  // ----------------------------------------------------
  Future<void> _editBrandProfile(BrandModel brand) async {
    final registration = widget.state.brandRegistrations
        .where((r) => r.id == brand.id)
        .firstOrNull;
    if (registration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brand registration not found.')),
      );
      return;
    }
    final saved = await showBrandProfileEditDialog(context, registration);
    if (saved == null || !mounted) return;
    widget.state.replaceBrandRegistration(saved);
    await widget.state.loadAdminQueues();
    await widget.state.initFromBackend();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Brand profile updated.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showEditLocationDialog(BrandModel brand) {
    bool isPhysical = brand.isPhysicalStore;
    final cityCtrl = TextEditingController(text: brand.city ?? '');
    final areaCtrl = TextEditingController(text: brand.area ?? '');
    final addressCtrl = TextEditingController(text: brand.address ?? '');
    final timingsCtrl = TextEditingController(
      text: brand.timings ?? '10:00 AM - 09:30 PM',
    );
    final mapsUrlCtrl = TextEditingController(text: brand.googleMapsUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.pureWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Edit Physical Store: ${brand.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: AppTheme.pureBlack,
                    title: const Text(
                      'Enable in "Nearby" Local Section',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: const Text(
                      'Consumers in this city can discover and get directions',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: isPhysical,
                    onChanged: (val) => setDialogState(() => isPhysical = val),
                  ),
                  const Divider(height: 20),
                  TextField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'e.g. Bengaluru, Mumbai, Jaipur',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Neighbourhood',
                      hintText: 'e.g. Indiranagar, Bandra West',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Complete Address',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timingsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Timings',
                      hintText: '10:00 AM - 09:30 PM',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mapsUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Google Maps Link',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  brand.isPhysicalStore = isPhysical;
                  brand.storeType = isPhysical ? 'local_store' : 'online_d2c';
                  brand.city = cityCtrl.text.trim();
                  brand.area = areaCtrl.text.trim();
                  brand.address = addressCtrl.text.trim();
                  brand.timings = timingsCtrl.text.trim();
                  brand.googleMapsUrl = mapsUrlCtrl.text.trim();

                  widget.state.updateBrand(brand);
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Boutique location for ${brand.name} updated!',
                      ),
                      backgroundColor: AppTheme.pureBlack,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Save Boutique Details'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // VERIFY & REDEEM VOUCHER AT COUNTER
  // ----------------------------------------------------
  Future<void> _handleCounterRedeem() async {
    final code = _adminVoucherController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isVerifyingVoucher = true;
      _verificationResult = null;
    });

    final res = await widget.state.verifyAndRedeemCounterVoucher(code);

    if (mounted) {
      setState(() {
        _isVerifyingVoucher = false;
        _verificationResult = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingRegs = widget.state.pendingRegistrations.length;
    final pendingCustomers = widget.state.pendingCustomerApprovals;
    final pendingSessions = widget.state.pendingSessionRequests.length;

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          if (widget.onSignOut != null)
            TextButton.icon(
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out'),
            ),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(pendingRegs, pendingCustomers, pendingSessions),
          const VerticalDivider(width: 1, color: AppTheme.surfaceLight),
          Expanded(
            child: Column(
              children: [
                _buildOverviewStats(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildCategoriesTab(),
                      _buildSessionsTab(),
                      _buildBrandsTab(),
                      _buildCounterScannerTab(),
                      _buildRegistrationsTab(),
                      _buildCustomerApprovalsTab(),
                      _buildSessionRequestsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    int pendingRegs,
    int pendingCustomers,
    int pendingSessions,
  ) {
    final items = <(IconData, String, int)>[
      (Icons.category_outlined, 'Categories', 0),
      (Icons.auto_awesome_outlined, 'Generative Sessions', 0),
      (Icons.storefront_outlined, 'Brands & Boutiques', 0),
      (Icons.qr_code_scanner, 'Counter Scanner', 0),
      (Icons.how_to_reg_outlined, 'Registrations', pendingRegs),
      (Icons.person_add_alt_outlined, 'Customer Approvals', pendingCustomers),
      (Icons.inbox_outlined, 'Session Requests', pendingSessions),
    ];
    return Container(
      width: 240,
      color: AppTheme.pureWhite,
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            children: [
              for (var i = 0; i < items.length; i++)
                _buildSidebarItem(
                  icon: items[i].$1,
                  label: items[i].$2,
                  badge: items[i].$3,
                  selected: _tabController.index == i,
                  onTap: () => _tabController.animateTo(i),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required int badge,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppTheme.surfaceLight : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppTheme.pureBlack : AppTheme.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppTheme.pureBlack
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
                if (badge > 0) _buildBadge(badge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewStats() {
    final activeSessions = widget.state.sessions
        .where((s) => s.status == 'active')
        .length;
    final approvedBrands = widget.state.approvedBrands.length;
    final stats = [
      ('Pending registrations', widget.state.pendingRegistrations.length),
      ('Pending session requests', widget.state.pendingSessionRequests.length),
      ('Active sessions', activeSessions),
      ('Approved brands', approvedBrands),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final (label, value) in stats)
            Container(
              width: 170,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: CATEGORIES MANAGER
  // ----------------------------------------------------
  Widget _buildCategoriesTab() {
    final categories = widget.state.allCategories;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DYNAMIC CATEGORIES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${categories.length} Total Categories configured',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...categories.map((cat) {
          final brandCount = widget.state.brands
              .where((b) => b.categoryId == cat.id)
              .length;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    size: 20,
                    color: AppTheme.pureBlack,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pureBlack,
                        ),
                      ),
                      Text(
                        '${cat.scope == 'nearby' ? 'Nearby' : 'Brands'} • $brandCount linked • Slug: ${cat.slug}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Rename Category',
                  onPressed: () => _showCategoryDialog(
                    categoryId: cat.id,
                    currentName: cat.name,
                    currentScope: cat.scope,
                  ),
                ),
                Switch.adaptive(
                  value: cat.isActive,
                  activeTrackColor: AppTheme.pureBlack,
                  onChanged: (val) {
                    widget.state.updateCategory(
                      cat.id,
                      cat.name,
                      isActive: val,
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showSessionPoolDialog(SessionModel session, String brandName) {
    showDialog(
      context: context,
      builder: (_) => SessionPoolDialog(
        session: session,
        brandName: brandName,
        onUpdated: widget.state.updateSession,
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 2: GENERATIVE SESSIONS MANAGER
  // ----------------------------------------------------
  Widget _buildSessionsTab() {
    final sessions = widget.state.sessions;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GENERATIVE SESSIONS CONFIG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${sessions.length} Live Drops published',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showCreateSessionDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Schedule Drop'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.flash_off_rounded,
                  size: 40,
                  color: AppTheme.textTertiary,
                ),
                SizedBox(height: 12),
                Text(
                  'No Live Sessions scheduled yet.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Approve brand session requests or click "Schedule Drop" above to launch.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                ),
              ],
            ),
          )
        else
          ...sessions.map((session) {
            final allBrands = [
              ...widget.state.brands,
              ...widget.state.nearbyStores,
            ];
            final matching = allBrands.where((b) => b.id == session.brandId);
            final brandName = matching.isNotEmpty
                ? matching.first.name
                : (session.title.isNotEmpty ? session.title : 'Live Session');
            final isPhysical =
                matching.isNotEmpty && matching.first.isPhysicalStore;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            brandName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (isPhysical) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.pureBlack,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'IN-STORE',
                                style: TextStyle(
                                  color: AppTheme.pureWhite,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: session.status == 'active'
                              ? AppTheme.pureBlack
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          session.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: session.status == 'active'
                                ? AppTheme.pureWhite
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Session created by: ${session.sessionCreatedBy}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Wait: ${session.waitingDurationSeconds}s',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          session.discountValue,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${session.claimedVouchersCount} Claimed',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => _showSessionPoolDialog(session, brandName),
                        icon: const Icon(Icons.groups_outlined, size: 16),
                        label: const Text('Manage pool'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.pureBlack,
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ----------------------------------------------------
  // TAB 3: BRAND PARTNERS & PHYSICAL BOUTIQUES
  // ----------------------------------------------------
  Widget _buildBrandsTab() {
    final allBrands = <BrandModel>[
      ...widget.state.brands,
      ...widget.state.nearbyStores.where(
        (n) => !widget.state.brands.any((b) => b.id == n.id),
      ),
    ];

    final filteredBrands = _brandFilter == 'physical'
        ? allBrands.where((b) => b.isPhysicalStore).toList()
        : (_brandFilter == 'online'
              ? allBrands.where((b) => !b.isPhysicalStore).toList()
              : allBrands);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'PARTNER ECOSYSTEM & BOUTIQUES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage online brands and physical city boutiques for the "Nearby" section.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 14),

        // Filter Pills
        Row(
          children: [
            _buildFilterChip('all', 'All (${allBrands.length})'),
            const SizedBox(width: 8),
            _buildFilterChip(
              'physical',
              '📍 Physical Boutiques (${allBrands.where((b) => b.isPhysicalStore).length})',
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'online',
              '🌐 Online D2C (${allBrands.where((b) => !b.isPhysicalStore).length})',
            ),
          ],
        ),

        const SizedBox(height: 16),
        if (filteredBrands.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.store_mall_directory_outlined,
                  size: 40,
                  color: AppTheme.textTertiary,
                ),
                SizedBox(height: 12),
                Text(
                  'No brands in this category yet.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Real brands will appear here once approved in the Registrations tab.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                ),
              ],
            ),
          )
        else
          ...filteredBrands.map((brand) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          brand.logoUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 44,
                                height: 44,
                                color: AppTheme.surfaceLight,
                                child: Icon(
                                  brand.isPhysicalStore
                                      ? Icons.store
                                      : Icons.shopping_bag,
                                  size: 20,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  brand.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (brand.isPhysicalStore) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.pureBlack,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '📍 ${brand.city ?? "Local"}',
                                      style: const TextStyle(
                                        color: AppTheme.pureWhite,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              brand.isPhysicalStore
                                  ? (brand.address ?? brand.area ?? 'Boutique')
                                  : brand.websiteUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ChoiceChip(
                        label: Text(
                          brand.isApproved ? 'APPROVED' : 'PENDING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: brand.isApproved
                                ? AppTheme.pureWhite
                                : AppTheme.pureBlack,
                          ),
                        ),
                        selected: brand.isApproved,
                        selectedColor: AppTheme.pureBlack,
                        backgroundColor: AppTheme.surfaceLight,
                        onSelected: (val) {
                          _runAdminAction(
                            widget.state.approveBrand(brand.id, val),
                            val ? 'Brand approved.' : 'Brand hidden.',
                            Colors.green,
                          );
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _editBrandProfile(brand),
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Edit Profile'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showEditLocationDialog(brand),
                        icon: const Icon(
                          Icons.edit_location_alt_outlined,
                          size: 14,
                        ),
                        label: Text(
                          brand.isPhysicalStore
                              ? 'Edit Store Location'
                              : 'Convert to Physical Store',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _brandFilter == key;
    return InkWell(
      onTap: () => setState(() => _brandFilter = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.pureBlack : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.pureBlack : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? AppTheme.pureWhite : AppTheme.pureBlack,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 4: COUNTER SCANNER & VOUCHER VERIFIER TERMINAL
  // ----------------------------------------------------
  Widget _buildCounterScannerTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.pureBlack,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.point_of_sale,
                    color: AppTheme.pureWhite,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COUNTER SCANNER & VOUCHER TERMINAL',
                        style: TextStyle(
                          color: AppTheme.pureWhite,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Universal in-store redemption engine for offline boutiques',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _adminVoucherController,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter Voucher Code (e.g. ZUBIX-BRAND-30)',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textTertiary,
                      letterSpacing: 0.5,
                    ),
                    prefixIcon: Icon(Icons.qr_code, color: AppTheme.pureBlack),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifyingVoucher ? null : _handleCounterRedeem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.pureBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifyingVoucher
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.pureBlack,
                          ),
                        )
                      : const Text(
                          'VERIFY & MARK REDEEMED AT COUNTER',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              if (_verificationResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
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
                          : (_verificationResult!['alreadyRedeemed'] == true
                                ? Colors.amber
                                : Colors.red),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _verificationResult!['success'] == true
                            ? Icons.check_circle
                            : (_verificationResult!['alreadyRedeemed'] == true
                                  ? Icons.warning
                                  : Icons.error),
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _verificationResult!['message'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (_verificationResult!['voucher'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Discount: ${_verificationResult!["voucher"] is Map ? _verificationResult!["voucher"]["discountValue"] : _verificationResult!["voucher"].discountValue}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'RECENT COUNTER REDEMPTIONS',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.state.myVouchers.where((v) => v.isRedeemed).map((v) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.brandName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Code: ${v.code} • ${v.discountValue}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'REDEEMED',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ----------------------------------------------------
  // TAB 5: BRAND REGISTRATIONS
  // ----------------------------------------------------
  Widget _buildCustomerApprovalsTab() {
    final customers = widget.state.customerApprovals;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'Awaiting Approval',
                '${customers.length}',
                customers.isNotEmpty
                    ? const Color(0xFFDC2626)
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (customers.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Text(
              'No customers waiting for approval',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          )
        else
          ...customers.map(_buildCustomerApprovalCard),
        const SizedBox(height: 32),
        const AdminCustomersPanel(),
      ],
    );
  }

  Widget _buildCustomerApprovalCard(Map<String, dynamic> customer) {
    final id = customer['id'] as String;
    final name = (customer['name'] as String?)?.trim() ?? '';
    final contact = [
      customer['phone'],
      customer['email'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    final location = [
      customer['district'],
      customer['state'],
      customer['country'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    final appliedOn =
        (customer['createdAt'] as String?)?.split('T').first ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'New customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (contact.isNotEmpty)
                  Text(
                    contact,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                if (location.isNotEmpty)
                  Text(
                    location,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                if (appliedOn.isNotEmpty)
                  Text(
                    'Signed up $appliedOn',
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _reviewCustomer(id, approve: false),
            child: const Text('Reject'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _reviewCustomer(id, approve: true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewCustomer(String id, {required bool approve}) async {
    final ok = await widget.state.reviewCustomerApproval(id, approve: approve);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (approve ? 'Customer approved' : 'Customer rejected')
              : 'Could not update the customer. Please try again.',
        ),
      ),
    );
  }

  Widget _buildRegistrationsTab() {
    final allRegs = widget.state.brandRegistrations;
    final filtered = _regFilter == 'all'
        ? allRegs
        : allRegs.where((r) => r.status == _regFilter).toList();

    final pendingCount = allRegs.where((r) => r.status == 'pending').length;
    final approvedCount = allRegs.where((r) => r.status == 'approved').length;
    final rejectedCount = allRegs.where((r) => r.status == 'rejected').length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'Pending Requests',
                '$pendingCount',
                pendingCount > 0
                    ? const Color(0xFFDC2626)
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                'Approved Brands',
                '$approvedCount',
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                'Rejected',
                '$rejectedCount',
                AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPillChip(
                'All (${allRegs.length})',
                _regFilter == 'all',
                () {
                  setState(() => _regFilter = 'all');
                },
              ),
              const SizedBox(width: 8),
              _buildPillChip(
                'Pending ($pendingCount)',
                _regFilter == 'pending',
                () {
                  setState(() => _regFilter = 'pending');
                },
              ),
              const SizedBox(width: 8),
              _buildPillChip(
                'Approved ($approvedCount)',
                _regFilter == 'approved',
                () {
                  setState(() => _regFilter = 'approved');
                },
              ),
              const SizedBox(width: 8),
              _buildPillChip(
                'Rejected ($rejectedCount)',
                _regFilter == 'rejected',
                () {
                  setState(() => _regFilter = 'rejected');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 40,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No applications in "${_regFilter.toUpperCase()}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...filtered.map((reg) => _buildRegistrationCard(reg)),
      ],
    );
  }

  Widget _buildRegistrationCard(BrandRegistrationModel reg) {
    final isPending = reg.status == 'pending';
    final isApproved = reg.status == 'approved';
    final isRejected = reg.status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? const Color(0xFFDC2626).withValues(alpha: 0.3)
              : AppTheme.borderLight,
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.pureBlack,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    reg.brandName.isNotEmpty
                        ? reg.brandName[0].toUpperCase()
                        : 'B',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reg.brandName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        _buildStatusBadge(reg.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: reg.brandType == 'online_d2c'
                                ? Colors.blue.shade50
                                : Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reg.brandType == 'online_d2c'
                                ? 'ONLINE D2C'
                                : 'NEARBY LOCAL STORE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: reg.brandType == 'online_d2c'
                                  ? Colors.blue.shade800
                                  : Colors.purple.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Applied ${_formatSimpleDate(reg.appliedAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Details grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildDetailItem('Owner', reg.ownerName),
              _buildDetailItem('Phone', reg.ownerPhone),
              _buildDetailItem('Email', reg.ownerEmail),
              if (reg.websiteUrl != null && reg.websiteUrl!.isNotEmpty)
                _buildDetailItem('Website', reg.websiteUrl!),
              if (reg.instagramUrl != null && reg.instagramUrl!.isNotEmpty)
                _buildDetailItem('Instagram', reg.instagramUrl!),
              for (final c in socialChannels)
                if (c.key != 'instagram' && (reg.socialLinks[c.key] ?? '').trim().isNotEmpty)
                  _buildDetailItem(c.label, reg.socialLinks[c.key]!),
              if (reg.city != null && reg.city!.isNotEmpty)
                _buildDetailItem(
                  'City / Area',
                  '${reg.city} • ${reg.area ?? ""}',
                ),
            ],
          ),

          if (reg.address != null && reg.address!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildDetailItem('Store Address', reg.address!),
          ],

          if (reg.description != null && reg.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reg.description!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],

          if (isApproved) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Portal Access Active • Login: ${reg.ownerEmail} (Password configured at signup)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isRejected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rejected: ${reg.rejectionReason ?? "Does not meet brand criteria"}. Brand can reapply.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApproveRegistration(reg),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve & Onboard Brand'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pureBlack,
                      foregroundColor: AppTheme.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _handleRejectRegistration(reg),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                  label: const Text(
                    'Reject',
                    style: TextStyle(color: Color(0xFFDC2626)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleApproveRegistration(BrandRegistrationModel reg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve "${reg.brandName}"?'),
        content: Text(
          'This will authorize the brand.\n\n'
          '• A brand profile will be onboarded.\n'
          '• Brand can log in to the Brand Dashboard at /brands using email "${reg.ownerEmail}" and their set password.\n'
          '• They will be enabled to submit Generative Session requests.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _runAdminAction(
                widget.state.approveBrandRegistration(reg.id),
                '"${reg.brandName}" approved successfully!',
                Colors.green,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pureBlack,
            ),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );
  }

  void _handleRejectRegistration(BrandRegistrationModel reg) {
    final reasonCtrl = TextEditingController(
      text: 'Brand portfolio/documentation incomplete',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject "${reg.brandName}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the reason for rejection. The brand will see this note and have the option to reapply:',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              Navigator.pop(ctx);
              Navigator.pop(ctx);
              _runAdminAction(
                widget.state.rejectBrandRegistration(
                  reg.id,
                  reason.isEmpty ? 'Criteria not met' : reason,
                ),
                'Registration for "${reg.brandName}" rejected.',
                Colors.red.shade700,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Reject Application'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 6: SESSION REQUESTS (Brand Generative Sessions)
  // ----------------------------------------------------
  Widget _buildSessionRequestsTab() {
    final allRequests = widget.state.sessionRequests;
    final filtered = _sessionReqFilter == 'all'
        ? allRequests
        : allRequests.where((r) => r.status == _sessionReqFilter).toList();

    final pendingCount = allRequests
        .where((r) => r.status == 'pending_approval')
        .length;
    final proposedCount = allRequests
        .where((r) => r.status == 'dates_proposed')
        .length;
    final confirmedCount = allRequests
        .where((r) => r.status == 'brand_confirmed')
        .length;
    final approvedCount = allRequests
        .where((r) => r.status == 'approved')
        .length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'Pending Requests',
                '$pendingCount',
                pendingCount > 0
                    ? const Color(0xFFDC2626)
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                'Dates Countered',
                '$proposedCount',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                'Ready for Final',
                '$confirmedCount',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                'Live / Approved',
                '$approvedCount',
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPillChip(
                'All (${allRequests.length})',
                _sessionReqFilter == 'all',
                () {
                  setState(() => _sessionReqFilter = 'all');
                },
              ),
              const SizedBox(width: 8),
              _buildPillChip(
                'Pending Review ($pendingCount)',
                _sessionReqFilter == 'pending_approval',
                () {
                  setState(() => _sessionReqFilter = 'pending_approval');
                },
              ),
              const SizedBox(width: 8),
              _buildPillChip(
                'Date Countered ($proposedCount)',
                _sessionReqFilter == 'dates_proposed',
                () {
                  setState(() => _sessionReqFilter = 'dates_proposed');
                },
              ),
              const SizedBox(width: 8),
              _buildPillChip(
                'Brand Confirmed ($confirmedCount)',
                _sessionReqFilter == 'brand_confirmed',
                () {
                  setState(() => _sessionReqFilter = 'brand_confirmed');
                },
              ),
              const SizedBox(width: 8),
              _buildPillChip(
                'Approved / Scheduled ($approvedCount)',
                _sessionReqFilter == 'approved',
                () {
                  setState(() => _sessionReqFilter = 'approved');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.bolt_outlined,
                  size: 40,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No session requests in "${_sessionReqFilter.toUpperCase()}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...filtered.map((req) => _buildSessionRequestCard(req)),
      ],
    );
  }

  Widget _buildSessionRequestCard(SessionRequestModel req) {
    final isPending = req.status == 'pending_approval';
    final isProposed = req.status == 'dates_proposed';
    final isBrandConfirmed = req.status == 'brand_confirmed';
    final isApproved = req.status == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending || isBrandConfirmed
              ? AppTheme.pureBlack
              : AppTheme.borderLight,
          width: isPending || isBrandConfirmed ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.pureBlack,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            req.brandName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        _buildSessionStatusBadge(req.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requested Date: ${_formatSimpleDate(req.requestedDate)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Created by: ${req.createdBy ?? '—'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Coupon Tiers breakdown
          const Text(
            'COUPON TIERS & POOL DISTRIBUTION:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                ...req.couponTiers.map(
                  (tier) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.pureBlack,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${tier.discountPct}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'allocated for ${tier.slots} shoppers',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Vouchers Pool:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${req.totalSlots} Vouchers',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (req.additionalNotes != null &&
              req.additionalNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Brand Notes: "${req.additionalNotes}"',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
          ],

          if (isProposed && req.proposedDates.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin Countered with: ${req.proposedDates.map(_formatSimpleDate).join(", ")}. Waiting for brand choice.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isBrandConfirmed && req.confirmedDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Brand accepted alternative date: ${_formatSimpleDate(req.confirmedDate!)}. Ready to finalize.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isApproved) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Session Approved & Live! Users can now join this Generative Session in Zubix App.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons
          if (isPending || isBrandConfirmed) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _runAdminAction(
                        widget.state.approveSessionRequest(req.id),
                        'Session for "${req.brandName}" is now APPROVED & SCHEDULED!',
                        Colors.green,
                      );
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      isBrandConfirmed
                          ? 'Confirm Final & Launch'
                          : '1. Accept & Schedule Live',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pureBlack,
                      foregroundColor: AppTheme.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _handleProposeDatesDialog(req),
                    icon: const Icon(Icons.calendar_month_outlined, size: 16),
                    label: const Text('2. Propose Dates'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.pureBlack,
                      side: const BorderSide(color: AppTheme.pureBlack),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _handleRejectSessionDialog(req),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFDC2626),
                    ),
                    tooltip: 'Reject Request',
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleProposeDatesDialog(SessionRequestModel req) {
    final now = DateTime.now();
    // Default 3 available alternative slots
    final opt1 = req.requestedDate.add(const Duration(days: 3));
    final opt2 = req.requestedDate.add(const Duration(days: 7));
    final opt3 = req.requestedDate.add(const Duration(days: 10));

    final selectedDates = <DateTime>[opt1, opt2];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Propose Dates for ${req.brandName}'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brand requested: ${_formatSimpleDate(req.requestedDate)}.\n'
                    'Select available days to propose to the brand so they can pick one:',
                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ...[opt1, opt2, opt3].map((date) {
                    final isChecked = selectedDates.any(
                      (d) =>
                          d.year == date.year &&
                          d.month == date.month &&
                          d.day == date.day,
                    );
                    return CheckboxListTile(
                      dense: true,
                      value: isChecked,
                      title: Text(
                        _formatSimpleDate(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${date.difference(now).inDays} days from now',
                      ),
                      activeColor: AppTheme.pureBlack,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedDates.add(date);
                          } else {
                            selectedDates.removeWhere(
                              (d) =>
                                  d.year == date.year &&
                                  d.month == date.month &&
                                  d.day == date.day,
                            );
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedDates.isEmpty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _runAdminAction(
                          widget.state.proposeAlternateDates(
                            req.id,
                            selectedDates,
                          ),
                          'Alternative dates proposed to "${req.brandName}"!',
                          Colors.orange.shade800,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pureBlack,
                ),
                child: const Text('Send Proposed Dates to Brand'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleRejectSessionDialog(SessionRequestModel req) {
    final reasonCtrl = TextEditingController(
      text: 'Scheduling conflict or high slot congestion',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Session for "${req.brandName}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter reason for declining this session request:',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _runAdminAction(
                widget.state.rejectSessionRequest(
                  req.id,
                  reasonCtrl.text.trim(),
                ),
                'Session request declined.',
                Colors.red.shade700,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Decline Request'),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.pureBlack : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.pureBlack : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'APPROVED';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'REJECTED';
        break;
      default:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'PENDING REVIEW';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _buildSessionStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'APPROVED / LIVE';
        break;
      case 'dates_proposed':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        label = 'DATES COUNTERED';
        break;
      case 'brand_confirmed':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'BRAND CONFIRMED DATE';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'REJECTED';
        break;
      default:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'PENDING APPROVAL';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  String _formatSimpleDate(DateTime d) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
