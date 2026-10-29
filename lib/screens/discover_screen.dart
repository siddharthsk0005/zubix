import 'package:flutter/material.dart';
import '../models/brand_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_card.dart';
import '../widgets/zubix_app_bar.dart';

class DiscoverScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onSessionJoined;

  const DiscoverScreen({
    super.key,
    required this.state,
    required this.onSessionJoined,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _searchOpen = false;

  void _toggleSearch() {
    setState(() {
      if (_searchOpen) {
        _searchOpen = false;
        _searchController.clear();
        _searchQuery = '';
        _searchFocus.unfocus();
      } else {
        _searchOpen = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _searchFocus.requestFocus();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
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
        return b.storeType == 'online_d2c' && (b.name.toLowerCase().contains(query) ||
            b.tagline.toLowerCase().contains(query) ||
            b.bio.toLowerCase().contains(query));
      }).toList();
    } else {
      list = widget.state.getBrandsForCategory(widget.state.selectedCategoryId);
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
          ZubixSliverAppBar(
            state: widget.state,
            searchOpen: _searchOpen,
            searchController: _searchController,
            searchFocus: _searchFocus,
            searchHint: 'Search brands, streetwear, audio...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            onToggleSearch: _toggleSearch,
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
                  // Dynamic Category Chips
                  ...activeCategories.map((cat) {
                    final isSelected =
                        _searchQuery.isEmpty &&
                        cat.id == widget.state.selectedCategoryId;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: Icon(
                          _getCategoryIcon(cat.iconName),
                          size: 14,
                          color: isSelected
                              ? AppTheme.pureWhite
                              : AppTheme.pureBlack,
                        ),
                        label: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.pureWhite
                                : AppTheme.pureBlack,
                          ),
                        ),
                        selectedColor: AppTheme.pureBlack,
                        backgroundColor: AppTheme.surfaceLight,
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.pureBlack
                              : AppTheme.borderLight,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
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
                          const Icon(
                            Icons.search_off_outlined,
                            size: 54,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No brands matching "$_searchQuery"'
                                : 'No Active Brands in this Category',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.pureBlack,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try a different search term or explore other categories.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            child: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final brand = filteredBrands[index];
                      final activeSession = widget.state
                          .getActiveSessionForBrand(brand.id);

                      return BrandCard(
                        brand: brand,
                        categoryName: widget.state.categoryNameFor(brand.categoryId),
                        session: activeSession,
                        joined: activeSession != null &&
                            widget.state.hasJoinedSession(activeSession.id),
                        onJoinSession: () async {
                          if (activeSession != null) {
                            final error = await widget.state.joinSession(activeSession, brand);
                            if (!context.mounted) return;
                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
                              );
                              return;
                            }
                            widget.onSessionJoined();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No active Generative Session available for this brand right now.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        onViewDetails: () {},
                      );
                    }, childCount: filteredBrands.length),
                  ),
          ),
        ],
      ),
    );
  }
}
