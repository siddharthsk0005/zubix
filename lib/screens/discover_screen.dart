import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_card.dart';
import 'admin_screen.dart';

class DiscoverScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onNavigateToSessions;

  const DiscoverScreen({
    super.key,
    required this.state,
    required this.onNavigateToSessions,
  });

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

  @override
  Widget build(BuildContext context) {
    final activeCategories = state.categories;
    final brandsForSelectedCategory = state.getBrandsForCategory(state.selectedCategoryId);

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
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(state: state)));
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: activeCategories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = activeCategories[index];
                    final isSelected = cat.id == state.selectedCategoryId;

                    return ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(
                        _getCategoryIcon(cat.iconName),
                        size: 15,
                        color: isSelected ? AppTheme.pureWhite : AppTheme.pureBlack,
                      ),
                      label: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 12.5,
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
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      onSelected: (_) {
                        state.selectCategory(cat.id);
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // Brands List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: brandsForSelectedCategory.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_outlined, size: 54, color: AppTheme.textTertiary),
                          const SizedBox(height: 16),
                          const Text(
                            'No Active Brands in this Category',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.pureBlack),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Brands will appear here once approved by Admin.',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(state: state)));
                            },
                            child: const Text('Manage Brands in Admin Portal'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final brand = brandsForSelectedCategory[index];
                        final activeSession = state.getActiveSessionForBrand(brand.id);

                        return BrandCard(
                          brand: brand,
                          session: activeSession,
                          onJoinSession: () {
                            if (activeSession != null) {
                              state.joinSession(activeSession, brand);
                              onNavigateToSessions();
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
                      childCount: brandsForSelectedCategory.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
