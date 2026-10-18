import 'package:flutter/material.dart';
import '../models/brand_model.dart';
import '../models/session_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  final AppState state;

  const AdminScreen({super.key, required this.state});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter for Brands Tab
  String _brandFilter = 'all'; // 'all', 'online', 'physical'

  // Counter Scanner Terminal
  final TextEditingController _adminVoucherController = TextEditingController();
  bool _isVerifyingVoucher = false;
  Map<String, dynamic>? _verificationResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
  void _showCategoryDialog({String? categoryId, String? currentName}) {
    final textController = TextEditingController(text: currentName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          categoryId == null ? 'Add New Category' : 'Edit Category Name',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                if (categoryId == null) {
                  widget.state.addCategory(name);
                } else {
                  widget.state.updateCategory(categoryId, name);
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
      ...widget.state.nearbyStores.where((n) => !widget.state.brands.any((b) => b.id == n.id)),
    ];

    if (allBrands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one partner brand first.')),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Create Generative Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Featured Brand / Atelier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                            couponController.text = 'ZUBIX-LOCAL-${b.name.substring(0, b.name.length >= 4 ? 4 : b.name.length).toUpperCase()}';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // In-Store Drop Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Generates in-store counter barcode/QR for redemption',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
                      const Text('Waiting Duration: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${waitingSeconds}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: waitingSeconds.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    activeColor: AppTheme.pureBlack,
                    inactiveColor: AppTheme.borderLight,
                    onChanged: (v) => setDialogState(() => waitingSeconds = v.round()),
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
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  final newSession = SessionModel(
                    id: 'session_${DateTime.now().millisecondsSinceEpoch}',
                    title: isInStoreDrop ? 'In-Store Exclusive Drop' : 'Generative Drop Session',
                    brandId: selectedBrandId,
                    sessionCreatedBy: createdByController.text.trim().isEmpty ? 'Admin Team' : createdByController.text.trim(),
                    waitingDurationSeconds: waitingSeconds,
                    discountValue: discountController.text.trim(),
                    couponCode: couponController.text.trim().toUpperCase(),
                    status: 'active',
                  );
                  widget.state.addSession(newSession);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Generative Session created & published live!'),
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
  void _showEditLocationDialog(BrandModel brand) {
    bool isPhysical = brand.isPhysicalStore;
    final cityCtrl = TextEditingController(text: brand.city ?? '');
    final areaCtrl = TextEditingController(text: brand.area ?? '');
    final addressCtrl = TextEditingController(text: brand.address ?? '');
    final timingsCtrl = TextEditingController(text: brand.timings ?? '10:00 AM - 09:30 PM');
    final mapsUrlCtrl = TextEditingController(text: brand.googleMapsUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.pureWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Edit Physical Store: ${brand.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: AppTheme.pureBlack,
                    title: const Text('Enable in "Nearby" Local Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Consumers in this city can discover and get directions', style: TextStyle(fontSize: 11)),
                    value: isPhysical,
                    onChanged: (val) => setDialogState(() => isPhysical = val),
                  ),
                  const Divider(height: 20),
                  TextField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(labelText: 'City', hintText: 'e.g. Bengaluru, Mumbai, Jaipur'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaCtrl,
                    decoration: const InputDecoration(labelText: 'Neighbourhood', hintText: 'e.g. Indiranagar, Bandra West'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Complete Address'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timingsCtrl,
                    decoration: const InputDecoration(labelText: 'Timings', hintText: '10:00 AM - 09:30 PM'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mapsUrlCtrl,
                    decoration: const InputDecoration(labelText: 'Google Maps Link'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                      content: Text('Boutique location for ${brand.name} updated!'),
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
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      appBar: AppBar(
        title: const Text('Admin & Partner Portal'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.pureBlack,
          unselectedLabelColor: AppTheme.textTertiary,
          indicatorColor: AppTheme.pureBlack,
          indicatorWeight: 2.5,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Generative Sessions'),
            Tab(text: 'Brands & Boutiques'),
            Tab(text: 'Counter Scanner'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(),
          _buildSessionsTab(),
          _buildBrandsTab(),
          _buildCounterScannerTab(),
        ],
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.textSecondary),
                ),
                Text(
                  '${categories.length} Total Categories configured',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...categories.map((cat) {
          final brandCount = widget.state.brands.where((b) => b.categoryId == cat.id).length;

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
                  child: const Icon(Icons.category_outlined, size: 20, color: AppTheme.pureBlack),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.pureBlack),
                      ),
                      Text(
                        '$brandCount brands linked • Slug: ${cat.slug}',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Rename Category',
                  onPressed: () => _showCategoryDialog(categoryId: cat.id, currentName: cat.name),
                ),
                Switch.adaptive(
                  value: cat.isActive,
                  activeTrackColor: AppTheme.pureBlack,
                  onChanged: (val) {
                    widget.state.updateCategory(cat.id, cat.name, isActive: val);
                  },
                ),
              ],
            ),
          );
        }),
      ],
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.textSecondary),
                ),
                Text(
                  '${sessions.length} Live Drops published',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showCreateSessionDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Schedule Drop'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...sessions.map((session) {
          final allBrands = [
            ...widget.state.brands,
            ...widget.state.nearbyStores,
          ];
          final brand = allBrands.firstWhere(
            (b) => b.id == session.brandId,
            orElse: () => allBrands.first,
          );

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
                          brand.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        if (brand.isPhysicalStore) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.pureBlack,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'IN-STORE',
                              style: TextStyle(color: AppTheme.pureWhite, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: session.status == 'active' ? AppTheme.pureBlack : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        session.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: session.status == 'active' ? AppTheme.pureWhite : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Session created by: ${session.sessionCreatedBy}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Wait: ${session.waitingDurationSeconds}s', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(session.discountValue, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Text(
                      '${session.claimedVouchersCount} Claimed',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
      ...widget.state.nearbyStores.where((n) => !widget.state.brands.any((b) => b.id == n.id)),
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
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.textSecondary),
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
            _buildFilterChip('physical', '📍 Physical Boutiques (${allBrands.where((b) => b.isPhysicalStore).length})'),
            const SizedBox(width: 8),
            _buildFilterChip('online', '🌐 Online D2C (${allBrands.where((b) => !b.isPhysicalStore).length})'),
          ],
        ),

        const SizedBox(height: 16),
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
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 44,
                          height: 44,
                          color: AppTheme.surfaceLight,
                          child: Icon(brand.isPhysicalStore ? Icons.store : Icons.shopping_bag, size: 20),
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
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              if (brand.isPhysicalStore) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.pureBlack,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '📍 ${brand.city ?? "Local"}',
                                    style: const TextStyle(color: AppTheme.pureWhite, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            brand.isPhysicalStore ? (brand.address ?? brand.area ?? 'Boutique') : brand.websiteUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
                          color: brand.isApproved ? AppTheme.pureWhite : AppTheme.pureBlack,
                        ),
                      ),
                      selected: brand.isApproved,
                      selectedColor: AppTheme.pureBlack,
                      backgroundColor: AppTheme.surfaceLight,
                      onSelected: (val) {
                        widget.state.approveBrand(brand.id, val);
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
                      onPressed: () => _showEditLocationDialog(brand),
                      icon: const Icon(Icons.edit_location_alt_outlined, size: 14),
                      label: Text(brand.isPhysicalStore ? 'Edit Store Location' : 'Convert to Physical Store'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
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
          border: Border.all(color: isSelected ? AppTheme.pureBlack : AppTheme.borderLight),
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
                  Icon(Icons.point_of_sale, color: AppTheme.pureWhite, size: 24),
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
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  decoration: const InputDecoration(
                    hintText: 'Enter Voucher Code (e.g. ZUBIX-NOIR-30)',
                    hintStyle: TextStyle(fontSize: 13, color: AppTheme.textTertiary, letterSpacing: 0.5),
                    prefixIcon: Icon(Icons.qr_code, color: AppTheme.pureBlack),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isVerifyingVoucher
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pureBlack),
                        )
                      : const Text(
                          'VERIFY & MARK REDEEMED AT COUNTER',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
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
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _verificationResult!['message'] ?? '',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (_verificationResult!['voucher'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Discount: ${_verificationResult!["voucher"] is Map ? _verificationResult!["voucher"]["discountValue"] : _verificationResult!["voucher"].discountValue}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
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
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.textSecondary),
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
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.brandName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Code: ${v.code} • ${v.discountValue}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(6)),
                  child: const Text('REDEEMED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
