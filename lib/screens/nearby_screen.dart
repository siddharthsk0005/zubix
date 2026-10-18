import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/brand_model.dart';
import '../models/session_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/swipable_gallery.dart';

class NearbyScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onNavigateToSessions;

  const NearbyScreen({
    super.key,
    required this.state,
    required this.onNavigateToSessions,
  });

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  String _selectedFilter = 'all'; // 'all', 'active_drop', 'cafe', 'fashion', 'beauty'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _curatedLocations = [
    {'name': 'Indiranagar, Bengaluru', 'city': 'Bengaluru', 'area': 'Indiranagar'},
    {'name': 'Bandra West, Mumbai', 'city': 'Mumbai', 'area': 'Bandra West'},
    {'name': 'C-Scheme, Jaipur', 'city': 'Jaipur', 'area': 'C-Scheme'},
    {'name': 'Hauz Khas Village, Delhi', 'city': 'Delhi', 'area': 'Hauz Khas'},
    {'name': 'Koregaon Park, Pune', 'city': 'Pune', 'area': 'Koregaon Park'},
    {'name': 'Jubilee Hills, Hyderabad', 'city': 'Hyderabad', 'area': 'Jubilee Hills'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchMapDirections(String? mapUrl, String? address, String storeName) async {
    final query = Uri.encodeComponent('$storeName, ${address ?? ""}');
    final targetUrl = (mapUrl != null && mapUrl.isNotEmpty)
        ? mapUrl
        : 'https://www.google.com/maps/search/?api=1&query=$query';

    try {
      final uri = Uri.parse(targetUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $targetUrl'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location: $address'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _callStore(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _showLocationPickerModal() {
    final searchInputCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final query = searchInputCtrl.text.trim().toLowerCase();
            final filteredLocations = query.isEmpty
                ? _curatedLocations
                : _curatedLocations.where((loc) {
                    return loc['name']!.toLowerCase().contains(query) ||
                        loc['city']!.toLowerCase().contains(query) ||
                        loc['area']!.toLowerCase().contains(query);
                  }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Handle
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SELECT LOCATION',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: AppTheme.pureBlack,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Discover boutiques & drops in your city',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          icon: const Icon(Icons.close, size: 20, color: AppTheme.pureBlack),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: TextField(
                        controller: searchInputCtrl,
                        onChanged: (val) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search city or neighbourhood...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                          suffixIcon: searchInputCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    searchInputCtrl.clear();
                                    setModalState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // "Use current location" button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: InkWell(
                      onTap: () {
                        widget.state.setSelectedCity('Indiranagar, Bengaluru');
                        Navigator.pop(modalCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location updated: Indiranagar, Bengaluru (GPS verified)'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.pureBlack,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.my_location, color: AppTheme.pureWhite, size: 18),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Use Precise GPS Location',
                                    style: TextStyle(
                                      color: AppTheme.pureWhite,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    'Locates active stores within 5 km radius',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'FEATURED LUXURY DISTRICTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: filteredLocations.length,
                      separatorBuilder: (c, i) => const Divider(height: 1, color: AppTheme.borderLight),
                      itemBuilder: (_, idx) {
                        final item = filteredLocations[idx];
                        final isSelected = widget.state.selectedCity.toLowerCase().contains(item['city']!.toLowerCase());

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.pureBlack : AppTheme.surfaceLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_city,
                              size: 18,
                              color: isSelected ? AppTheme.pureWhite : AppTheme.pureBlack,
                            ),
                          ),
                          title: Text(
                            item['name']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: AppTheme.pureBlack,
                            ),
                          ),
                          subtitle: Text(
                            'Active Drop Boutiques Available',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? AppTheme.pureBlack : AppTheme.textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppTheme.pureBlack, size: 20)
                              : Icon(Icons.chevron_right, color: AppTheme.textTertiary.withValues(alpha: 0.6), size: 20),
                          onTap: () {
                            widget.state.setSelectedCity(item['name']!);
                            Navigator.pop(modalCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('City changed to ${item["name"]}'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStoreDetails(BrandModel store, SessionModel? session) {
    final effectiveSession = session ?? widget.state.getActiveSessionForBrand(store.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    SwipableGallery(
                      images: store.showcaseImages,
                      height: 240,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: AppTheme.pureBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                store.tagline,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (store.distanceKm != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.pureBlack,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${store.distanceKm!.toStringAsFixed(1)} KM',
                              style: const TextStyle(
                                color: AppTheme.pureWhite,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppTheme.borderLight),
                    const SizedBox(height: 16),
                    // Physical Location Details
                    const Text(
                      'BOUTIQUE INFORMATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_outlined, size: 20, color: AppTheme.pureBlack),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            store.address ?? '${store.area}, ${store.city}',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppTheme.pureBlack,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined, size: 20, color: AppTheme.pureBlack),
                        const SizedBox(width: 12),
                        Text(
                          store.timings ?? '10:00 AM - 09:30 PM',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.pureBlack,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (store.contactPhone.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 20, color: AppTheme.pureBlack),
                          const SizedBox(width: 12),
                          Text(
                            store.contactPhone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.pureBlack,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _callStore(store.contactPhone),
                            child: const Text('CALL STORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    const Divider(color: AppTheme.borderLight),
                    const SizedBox(height: 16),
                    const Text(
                      'ABOUT THE ATELIER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.bio,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Actions: Map & Drop
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _launchMapDirections(
                              store.googleMapsUrl,
                              store.address,
                              store.name,
                            ),
                            icon: const Icon(Icons.navigation_outlined, size: 18),
                            label: const Text('DIRECTIONS'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.pureBlack,
                              side: const BorderSide(color: AppTheme.pureBlack, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        if (effectiveSession != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                widget.state.joinSession(effectiveSession, store);
                                widget.onNavigateToSessions();
                              },
                              icon: const Icon(Icons.bolt, size: 18, color: AppTheme.pureWhite),
                              label: const Text('JOIN SESSION'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.pureBlack,
                                foregroundColor: AppTheme.pureWhite,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<BrandModel> _getFilteredStores() {
    var list = widget.state.nearbyStores;

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.tagline.toLowerCase().contains(q) ||
            (s.area != null && s.area!.toLowerCase().contains(q)) ||
            (s.city != null && s.city!.toLowerCase().contains(q));
      }).toList();
    }

    if (_selectedFilter == 'active_drop') {
      list = list.where((s) => widget.state.getActiveSessionForBrand(s.id) != null).toList();
    } else if (_selectedFilter == 'cafe') {
      list = list.where((s) => s.name.toLowerCase().contains('coffee') || s.name.toLowerCase().contains('cafe') || s.tagline.toLowerCase().contains('coffee')).toList();
    } else if (_selectedFilter == 'fashion') {
      list = list.where((s) => s.categoryId == 'cat_fashion').toList();
    } else if (_selectedFilter == 'beauty') {
      list = list.where((s) => s.categoryId == 'cat_beauty').toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final stores = _getFilteredStores();

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: CustomScrollView(
        slivers: [
          // App Bar with Location Selector
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            backgroundColor: AppTheme.pureWhite,
            surfaceTintColor: Colors.transparent,
            title: InkWell(
              onTap: _showLocationPickerModal,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me, size: 16, color: AppTheme.pureBlack),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.state.selectedCity.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Helvetica',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: AppTheme.pureBlack,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.pureBlack),
                          ],
                        ),
                        const Text(
                          'Local Boutiques & Active Drops',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh Stores',
                icon: widget.state.isLoadingNearby
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pureBlack),
                      )
                    : const Icon(Icons.refresh, color: AppTheme.pureBlack, size: 20),
                onPressed: () => widget.state.fetchNearbyStores(),
              ),
              IconButton(
                tooltip: 'Change City',
                icon: const Icon(Icons.tune_outlined, color: AppTheme.pureBlack, size: 20),
                onPressed: _showLocationPickerModal,
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Search Box & Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search atelier, cafe or neighbourhood...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Pills Strip
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('all', 'All Boutiques (${widget.state.nearbyStores.length})'),
                        const SizedBox(width: 8),
                        _buildFilterPill('active_drop', '⚡ Active Drops Only'),
                        const SizedBox(width: 8),
                        _buildFilterPill('cafe', '☕ Cafes & Ateliers'),
                        const SizedBox(width: 8),
                        _buildFilterPill('fashion', '✂ Fashion & Objects'),
                        const SizedBox(width: 8),
                        _buildFilterPill('beauty', '✦ Scent & Wellness'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Store List
          if (stores.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront_outlined, size: 48, color: AppTheme.textTertiary.withValues(alpha: 0.6)),
                      const SizedBox(height: 16),
                      Text(
                        'No boutiques found in ${widget.state.selectedCity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pureBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try switching to another city or explore all partner ateliers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          widget.state.setSelectedCity('Indiranagar, Bengaluru');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.pureBlack,
                          foregroundColor: AppTheme.pureWhite,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('SWITCH TO BENGALURU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final store = stores[index];
                    final session = widget.state.getActiveSessionForBrand(store.id);
                    return _buildStoreCard(store, session);
                  },
                  childCount: stores.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppTheme.pureWhite : AppTheme.pureBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildStoreCard(BrandModel store, SessionModel? session) {
    final effectiveSession = session ?? widget.state.getActiveSessionForBrand(store.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gallery
          Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                SwipableGallery(
                  images: store.showcaseImages,
                  height: 200,
                  borderRadius: BorderRadius.circular(14),
                ),
                // Distance badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.pureBlack.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me, size: 12, color: AppTheme.pureWhite),
                        const SizedBox(width: 4),
                        Text(
                          store.distanceKm != null ? '${store.distanceKm!.toStringAsFixed(1)} KM' : 'NEARBY',
                          style: const TextStyle(
                            color: AppTheme.pureWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Timings pill
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          store.timings ?? '10:00 AM - 09:30 PM',
                          style: const TextStyle(
                            color: AppTheme.pureBlack,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                              color: AppTheme.pureBlack,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            store.tagline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Area / Address
                Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        store.address ?? '${store.area}, ${store.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Generative Session Drop Banner with direct Join Button
                if (effectiveSession != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.pureBlack,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bolt, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                    'GENERATIVE DROP LIVE',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                effectiveSession.discountValue,
                                style: const TextStyle(
                                  color: AppTheme.pureWhite,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            widget.state.joinSession(effectiveSession, store);
                            widget.onNavigateToSessions();
                          },
                          icon: const Icon(Icons.bolt, size: 15, color: AppTheme.pureBlack),
                          label: const Text(
                            'JOIN SESSION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.pureWhite,
                            foregroundColor: AppTheme.pureBlack,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Buttons: Details & Directions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showStoreDetails(store, session),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.pureBlack,
                          side: const BorderSide(color: AppTheme.borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'VIEW ATELIER',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchMapDirections(
                          store.googleMapsUrl,
                          store.address,
                          store.name,
                        ),
                        icon: const Icon(Icons.directions, size: 14),
                        label: const Text(
                          'DIRECTIONS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceLight,
                          foregroundColor: AppTheme.pureBlack,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
