import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class WebDashboardScreen extends StatefulWidget {
  final AppState state;

  const WebDashboardScreen({super.key, required this.state});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  int _selectedSidebarIndex = 0; // 0: Overview, 1: Categories, 2: Sessions, 3: Partners

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: Row(
        children: [
          // 1. Sleek Monochrome Left Sidebar
          Container(
            width: 250,
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

                const SizedBox(height: 32),

                // Navigation Items
                _buildSidebarItem(0, 'Overview & Metrics', Icons.dashboard_outlined),
                _buildSidebarItem(1, 'Categories Manager', Icons.category_outlined),
                _buildSidebarItem(2, 'Generative Sessions', Icons.bolt_outlined),
                _buildSidebarItem(3, 'Partner Brands', Icons.storefront_outlined),

                const Spacer(),

                // Database Status Indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_done_outlined, size: 16, color: Colors.greenAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
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
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.phone_iphone, size: 16),
                              label: const Text('Back to Mobile View'),
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
        return 'Ecosystem Overview';
      case 1:
        return 'Category Architecture & Taxonomy';
      case 2:
        return 'Generative Session Scheduling';
      case 3:
        return 'Partner Onboarding & Brand Verification';
      default:
        return '';
    }
  }

  Widget _buildSidebarItem(int index, String title, IconData icon) {
    final isSelected = _selectedSidebarIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selectedTileColor: AppTheme.accentDark,
        leading: Icon(icon, size: 18, color: isSelected ? AppTheme.pureWhite : AppTheme.textSecondary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.pureWhite : AppTheme.textSecondary,
          ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatCard('Ecosystem Brands', '$approvedBrands Approved', '$totalBrands registered', Icons.storefront),
            const SizedBox(width: 16),
            _buildStatCard('Generative Sessions', '$totalSessions Active', 'Live on consumer app', Icons.bolt),
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
                final b = widget.state.brands.firstWhere((br) => br.id == s.brandId, orElse: () => widget.state.brands.first);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${s.waitingDurationSeconds}s waiting time', style: const TextStyle(color: AppTheme.textSecondary)),
                      Text(s.discountValue, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${s.claimedVouchersCount} claimed', style: const TextStyle(color: AppTheme.textSecondary)),
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

  Widget _buildStatCard(String label, String value, String subtext, IconData icon) {
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
            Icon(icon, size: 22, color: AppTheme.pureBlack),
            const SizedBox(height: 14),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text(subtext, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // CATEGORIES MANAGEMENT SECTION
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
                onPressed: () {
                  _showNewCategoryDialog();
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Category'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1.5))),
                children: [
                  Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('SLUG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('BRANDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
              ...categories.map((c) {
                final count = widget.state.brands.where((b) => b.categoryId == c.id).length;
                return TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(c.slug, style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Courier'))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text('$count brands')),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(c.isActive ? 'Active' : 'Disabled', style: TextStyle(color: c.isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _showNewCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        title: const Text('New Category', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Gourmet Coffee'),
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
            final b = widget.state.brands.firstWhere((br) => br.id == s.brandId, orElse: () => widget.state.brands.first);
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
                    child: Image.network(b.logoUrl, width: 44, height: 44, fit: BoxFit.cover),
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
                    child: Image.network(b.logoUrl, width: 48, height: 48, fit: BoxFit.cover),
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
}
