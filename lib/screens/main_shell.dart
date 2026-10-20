import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'discover_screen.dart';
import 'nearby_screen.dart';
import 'generative_session_screen.dart';
import 'profile_screen.dart';
import 'vouchers_screen.dart';

class MainShell extends StatefulWidget {
  final AppState state;

  const MainShell({super.key, required this.state});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _vouchersIndex = 2;
  static const _brandsIndex = 0;

  int _currentIndex = _brandsIndex;

  // Joining a session from Brands or Nearby opens the session room on top of the tabs.
  void _openSessionRoom() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => ListenableBuilder(
          listenable: widget.state,
          builder: (routeContext, _) => GenerativeSessionScreen(
            state: widget.state,
            onNavigateToVouchers: () {
              Navigator.of(routeContext).pop();
              setState(() => _currentIndex = _vouchersIndex);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeVouchersCount = widget.state.myVouchers
        .where((v) => !v.isRedeemed)
        .length;

    final screens = [
      DiscoverScreen(state: widget.state, onSessionJoined: _openSessionRoom),
      NearbyScreen(state: widget.state, onSessionJoined: _openSessionRoom),
      VouchersScreen(
        state: widget.state,
        onExploreBrands: () => setState(() => _currentIndex = _brandsIndex),
      ),
      ProfileScreen(state: widget.state),
    ];

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 680,
          ), // Responsive on web and tablets
          child: IndexedStack(index: _currentIndex, children: screens),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.pureWhite,
          selectedItemColor: AppTheme.pureBlack,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Brands',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.near_me_outlined),
              activeIcon: Icon(Icons.near_me),
              label: 'Nearby',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: activeVouchersCount > 0,
                label: Text(
                  '$activeVouchersCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: AppTheme.pureBlack,
                textColor: AppTheme.pureWhite,
                child: const Icon(Icons.card_giftcard_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: activeVouchersCount > 0,
                label: Text(
                  '$activeVouchersCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: AppTheme.pureBlack,
                textColor: AppTheme.pureWhite,
                child: const Icon(Icons.card_giftcard),
              ),
              label: 'My Vouchers',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
