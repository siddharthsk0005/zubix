import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'discover_screen.dart';
import 'generative_session_screen.dart';
import 'vouchers_screen.dart';

class MainShell extends StatefulWidget {
  final AppState state;

  const MainShell({super.key, required this.state});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final activeVouchersCount = widget.state.myVouchers.where((v) => !v.isRedeemed).length;

    final screens = [
      DiscoverScreen(
        state: widget.state,
        onNavigateToSessions: () => setState(() => _currentIndex = 1),
      ),
      GenerativeSessionScreen(
        state: widget.state,
        onNavigateToVouchers: () => setState(() => _currentIndex = 2),
      ),
      VouchersScreen(
        state: widget.state,
        onExploreSessions: () => setState(() => _currentIndex = 1),
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680), // Responsive on web and tablets
          child: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.bolt_outlined),
                  if (widget.state.participationStatus == SessionParticipationStatus.waiting)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.bolt),
              label: 'Generative',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: activeVouchersCount > 0,
                label: Text(
                  '$activeVouchersCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppTheme.pureBlack,
                textColor: AppTheme.pureWhite,
                child: const Icon(Icons.card_giftcard_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: activeVouchersCount > 0,
                label: Text(
                  '$activeVouchersCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppTheme.pureBlack,
                textColor: AppTheme.pureWhite,
                child: const Icon(Icons.card_giftcard),
              ),
              label: 'My Vouchers',
            ),
          ],
        ),
      ),
    );
  }
}
