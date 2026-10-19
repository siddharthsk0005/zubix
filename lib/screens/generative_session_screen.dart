import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class GenerativeSessionScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onNavigateToVouchers;

  const GenerativeSessionScreen({
    super.key,
    required this.state,
    required this.onNavigateToVouchers,
  });

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher code "$code" copied!'),
        backgroundColor: AppTheme.pureBlack,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openStore(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      appBar: AppBar(
        title: const Text('Generative Sessions'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (state.participationStatus) {
      case SessionParticipationStatus.waiting:
        return _buildWaitingRoom(context);
      case SessionParticipationStatus.completed:
        return _buildRewardUnlockedView(context);
      case SessionParticipationStatus.idle:
        return _buildLobby(context);
    }
  }

  // ------------------------------------------------------------------
  // 1. SESSION LOBBY
  // ------------------------------------------------------------------
  Widget _buildLobby(BuildContext context) {
    final activeSessions = state.sessions.where((s) => s.status == 'active').toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Explanation Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.pureBlack,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt, color: AppTheme.pureWhite, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'How Generative Sessions Work',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pureBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '1. Select any featured brand session below.\n'
                '2. Join the session and wait for the countdown.\n'
                '3. Win an exclusive brand discount voucher saved to "My Vouchers".',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LIVE ACTIVE SESSIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${activeSessions.length} Available',
              style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (activeSessions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No active sessions scheduled right now.'),
            ),
          )
        else
          ...activeSessions.map((session) {
            final allBrands = [...state.brands, ...state.nearbyStores];
            final brand = allBrands.firstWhere(
              (b) => b.id == session.brandId,
              orElse: () => allBrands.isNotEmpty ? allBrands.first : state.brands.first,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          brand.logoUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 44,
                            height: 44,
                            color: AppTheme.surfaceLight,
                            child: const Icon(Icons.store),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              brand.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.pureBlack,
                              ),
                            ),
                            Text(
                              'Session created by: ${session.sessionCreatedBy}',
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 12, color: AppTheme.pureBlack),
                            const SizedBox(width: 4),
                            Text(
                              '${session.waitingDurationSeconds}s wait',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GUARANTEED REWARD',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            session.discountValue,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.pureBlack,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => state.joinSession(session, brand),
                        child: const Text('Enter Session'),
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

  // ------------------------------------------------------------------
  // 2. ANTICIPATION WAITING ROOM
  // ------------------------------------------------------------------
  Widget _buildWaitingRoom(BuildContext context) {
    final brand = state.activeParticipatingBrand;
    final session = state.activeParticipatingSession;
    if (brand == null || session == null) return const SizedBox.shrink();

    final remaining = state.remainingSeconds;
    final total = state.totalWaitingSeconds;
    final progress = total > 0 ? (1.0 - (remaining / total)) : 0.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular countdown timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.pureBlack),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${remaining}s',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: AppTheme.pureBlack,
                      ),
                    ),
                    const Text(
                      'WAITING TIME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            Text(
              'Generating Your ${brand.name} Voucher',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.pureBlack,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Session created by: ${session.sessionCreatedBy}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 28),

            // Brand Story Box during wait
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  Text(
                    'ABOUT ${brand.name.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    brand.bio,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            OutlinedButton(
              onPressed: () => state.cancelParticipation(),
              child: const Text('Cancel & Exit Session'),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // 3. REWARD UNLOCKED VIEW
  // ------------------------------------------------------------------
  Widget _buildRewardUnlockedView(BuildContext context) {
    final voucher = state.latestUnlockedVoucher;
    if (voucher == null) return const SizedBox.shrink();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.pureBlack,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppTheme.pureWhite, size: 36),
            ),

            const SizedBox(height: 20),

            const Text(
              'CONGRATULATIONS!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You Won a Discount Voucher',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: AppTheme.pureBlack,
              ),
            ),

            const SizedBox(height: 24),

            // Voucher Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.pureBlack, width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    voucher.brandName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    voucher.discountValue,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppTheme.pureBlack,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          voucher.code,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () => _copyCode(context, voucher.code),
                          tooltip: 'Copy Code',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Saved to "My Vouchers" in your bottom navigation bar.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      state.dismissCompletedSession();
                      onNavigateToVouchers();
                    },
                    child: const Text('View My Vouchers'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openStore(context, voucher.brandWebsite),
                    child: const Text('Shop Online'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
