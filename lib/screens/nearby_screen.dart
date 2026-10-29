import 'package:flutter/material.dart';
import '../models/brand_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_card.dart';
import '../widgets/zubix_app_bar.dart';

class NearbyScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onSessionJoined;

  const NearbyScreen({
    super.key,
    required this.state,
    required this.onSessionJoined,
  });

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _searchOpen = false;
  @override
  void initState() {
    super.initState();
    widget.state.detectCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

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

  List<BrandModel> _getFilteredStores() {
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      return widget.state.nearbyStores.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.tagline.toLowerCase().contains(q) ||
            (s.area?.toLowerCase().contains(q) ?? false) ||
            (s.city?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    final catId = widget.state.selectedNearbyCategoryId;
    return widget.state.nearbyStores
        .where((s) => s.categoryId == catId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeCategories = widget.state.nearbyCategories;
    final stores = _getFilteredStores();

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: CustomScrollView(
        slivers: [
          ZubixSliverAppBar(
            state: widget.state,
            searchOpen: _searchOpen,
            searchController: _searchController,
            searchFocus: _searchFocus,
            searchHint: 'Search stores, cafes, fashion...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            onToggleSearch: _toggleSearch,
          ),

          // Category Chips (Nearby's own categories)
          SliverToBoxAdapter(
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ...activeCategories.map((cat) {
                    final isSelected =
                        _searchQuery.isEmpty &&
                        cat.id == widget.state.selectedNearbyCategoryId;

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
                          widget.state.selectNearbyCategory(cat.id);
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

          // Store List (same BrandCard list as Brands)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: stores.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.state.isLoadingNearby)
                            const CircularProgressIndicator(
                              color: AppTheme.pureBlack,
                            )
                          else ...[
                            const Icon(
                              Icons.search_off_outlined,
                              size: 54,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No brands matching "$_searchQuery"'
                                  : 'No Active Brands Nearby',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.pureBlack,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.state.locationError ??
                                  'Try a different category or location.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              onPressed: _searchQuery.isNotEmpty
                                  ? () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    }
                                  : widget.state.detectCurrentLocation,
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'Reset Filters'
                                    : 'Refresh Location',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final store = stores[index];
                      final session = widget.state.getActiveSessionForBrand(
                        store.id,
                      );
                      return BrandCard(
                        brand: store,
                        categoryName: widget.state.categoryNameFor(store.categoryId),
                        session: session,
                        joined: session != null &&
                            widget.state.hasJoinedSession(session.id),
                        onJoinSession: () async {
                          if (session != null) {
                            final error = await widget.state.joinSession(session, store);
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
                    }, childCount: stores.length),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
