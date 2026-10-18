import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
  // CREATE GENERATIVE SESSION DIALOG
  // ----------------------------------------------------
  void _showCreateSessionDialog() {
    final brands = widget.state.approvedBrands;
    if (brands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please approve at least one brand first.')),
      );
      return;
    }

    String selectedBrandId = brands.first.id;
    final createdByController = TextEditingController(text: 'Admin Curators');
    final discountController = TextEditingController(text: '30% FLAT OFF');
    final couponController = TextEditingController(text: 'ZUBIX-SPECIAL-30');
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
                  const Text('Select Featured Brand', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBrandId,
                    items: brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedBrandId = val);
                    },
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
                      hintText: 'e.g. 40% OFF or \$30 VOUCHER',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: couponController,
                    decoration: const InputDecoration(
                      labelText: 'Coupon Code Template',
                      hintText: 'e.g. ZUBIX-VIP-40',
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
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Generative Sessions'),
            Tab(text: 'Brand Partners'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(),
          _buildSessionsTab(),
          _buildBrandsTab(),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: CATEGORIES MANAGER (Flexible database/table)
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
                  '${sessions.length} Sessions configured',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showCreateSessionDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Session'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...sessions.map((session) {
          final brand = widget.state.brands.firstWhere(
            (b) => b.id == session.brandId,
            orElse: () => widget.state.brands.first,
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
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
                    Text(
                      brand.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                      '${session.claimedVouchersCount} Vouchers Claimed',
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
  // TAB 3: BRAND PARTNER APPROVALS
  // ----------------------------------------------------
  Widget _buildBrandsTab() {
    final brands = widget.state.brands;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'PARTNER ECOSYSTEM & APPROVALS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        const Text(
          'When brands register, admins can review and approve them here to join the live ecosystem.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        ...brands.map((brand) {
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    brand.logoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        brand.websiteUrl,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${brand.name} status updated!'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
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
}
