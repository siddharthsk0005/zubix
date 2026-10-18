import 'package:flutter/material.dart';
import '../models/brand_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_card.dart';
import '../widgets/profile_modal.dart';
import 'admin_screen.dart';

class DiscoverScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onNavigateToSessions;

  const DiscoverScreen({
    super.key,
    required this.state,
    required this.onNavigateToSessions,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _onlyWithActiveSession = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'checkroom':
        return Icons.checkroom;
      case 'spa':
        return Icons.spa;
      case 'home':
        return Icons.home_outlined;
      case 'brush':
        return Icons.brush_outlined;
      case 'devices':
        return Icons.devices_other;
      default:
        return Icons.category_outlined;
    }
  }

  List<BrandModel> _getFilteredBrands() {
    List<BrandModel> list;
    if (_searchQuery.trim().isNotEmpty) {
      // Search across all approved brands when user types a query
      final query = _searchQuery.toLowerCase();
      list = widget.state.approvedBrands.where((b) {
        return b.name.toLowerCase().contains(query) ||
            b.tagline.toLowerCase().contains(query) ||
            b.bio.toLowerCase().contains(query);
      }).toList();
    } else {
      list = widget.state.getBrandsForCategory(widget.state.selectedCategoryId);
    }

    if (_onlyWithActiveSession) {
      list = list.where((b) => widget.state.getActiveSessionForBrand(b.id) != null).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final activeCategories = widget.state.categories;
    final filteredBrands = _getFilteredBrands();

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: CustomScrollView(
        slivers: [
          // App Header
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            backgroundColor: AppTheme.pureWhite,
            surfaceTintColor: Colors.transparent,
            title: GestureDetector(
              onLongPress: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(state: widget.state)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entered Admin & Partner Control Center'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ZUBIX',
                    style: TextStyle(
                      fontFamily: 'Helvetica',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppTheme.pureBlack,
                    ),
                  ),
                  Text(
                    'Curated Brands • Generative Sessions',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle_outlined, color: AppTheme.pureBlack, size: 26),
                tooltip: 'Profile & Ecosystem',
                onPressed: () => ProfileModal.show(context, widget.state),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search brands, streetwear, audio...',
                    hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16, color: AppTheme.textSecondary),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                ),
              ),
            ),
          ),

          // Category Chips & Filter Row
          SliverToBoxAdapter(
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Active Sessions quick toggle
                  FilterChip(
                    selected: _onlyWithActiveSession,
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.bolt,
                      size: 14,
                      color: _onlyWithActiveSession ? AppTheme.pureWhite : AppTheme.pureBlack,
                    ),
                    label: Text(
                      'Live Sessions Only',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _onlyWithActiveSession ? FontWeight.w700 : FontWeight.w500,
                        color: _onlyWithActiveSession ? AppTheme.pureWhite : AppTheme.pureBlack,
                      ),
                    ),
                    selectedColor: AppTheme.pureBlack,
                    backgroundColor: AppTheme.surfaceLight,
                    side: BorderSide(
                      color: _onlyWithActiveSession ? AppTheme.pureBlack : AppTheme.borderLight,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    onSelected: (val) {
                      setState(() => _onlyWithActiveSession = val);
                    },
                  ),
                  const SizedBox(width: 8),

                  // Dynamic Category Chips
                  ...activeCategories.map((cat) {
                    final isSelected = _searchQuery.isEmpty && cat.id == widget.state.selectedCategoryId;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: Icon(
                          _getCategoryIcon(cat.iconName),
                          size: 14,
                          color: isSelected ? AppTheme.pureWhite : AppTheme.pureBlack,
                        ),
                        label: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppTheme.pureWhite : AppTheme.pureBlack,
                          ),
                        ),
                        selectedColor: AppTheme.pureBlack,
                        backgroundColor: AppTheme.surfaceLight,
                        side: BorderSide(
                          color: isSelected ? AppTheme.pureBlack : AppTheme.borderLight,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        onSelected: (_) {
                          if (_searchQuery.isNotEmpty) {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          }
                          widget.state.selectCategory(cat.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Divider(height: 1, color: AppTheme.borderLight),
          ),

          // Brands List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: filteredBrands.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_outlined, size: 54, color: AppTheme.textTertiary),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No brands matching "$_searchQuery"'
                                : 'No Active Brands in this Category',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.pureBlack),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try a different search term or explore other categories.',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _onlyWithActiveSession = false;
                              });
                            },
                            child: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final brand = filteredBrands[index];
                        final activeSession = widget.state.getActiveSessionForBrand(brand.id);

                        return BrandCard(
                          brand: brand,
                          session: activeSession,
                          onJoinSession: () {
                            if (activeSession != null) {
                              widget.state.joinSession(activeSession, brand);
                              widget.onNavigateToSessions();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No active Generative Session available for this brand right now.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          onViewDetails: () {},
                        );
                      },
                      childCount: filteredBrands.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
