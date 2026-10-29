import 'dart:async';
import 'package:flutter/material.dart';
import '../models/my_pool_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const _poolMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatPoolDateTime(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  final min = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${_poolMonths[d.month - 1]}, $hour12:$min $ampm';
}

class PoolScreen extends StatefulWidget {
  final AppState state;

  const PoolScreen({super.key, required this.state});

  @override
  State<PoolScreen> createState() => _PoolScreenState();
}

class _PoolScreenState extends State<PoolScreen> {
  Timer? _ticker;
  int _ticks = 0;
  final Set<String> _acknowledging = {};

  @override
  void initState() {
    super.initState();
    widget.state.loadMyPool();
    // Redraws the countdowns every second and refreshes from the server every 5 seconds.
    // Released vouchers also reload here, so they move from the Pool to Vouchers without a restart.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _ticks++;
      final now = DateTime.now();
      final anyWaiting = widget.state.myPool.any((e) => e.isWaiting);
      final anyDueRelease = widget.state.myPool.any(
        (e) => e.isAllotted && e.releaseAt != null && !e.releaseAt!.isAfter(now),
      );
      if (_ticks % 5 == 0) {
        if (anyWaiting) widget.state.loadMyPool();
        // A released voucher leaves the Pool on the server, so refresh both lists together.
        if (anyDueRelease) {
          widget.state.loadMyPool();
          widget.state.refreshVouchers();
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _acknowledge(MyPoolEntry entry) async {
    setState(() => _acknowledging.add(entry.id));
    final error = await widget.state.acknowledgePoolEntry(entry.id);
    if (!mounted) return;
    setState(() => _acknowledging.remove(entry.id));
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.pureBlack,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static String _countdown(Duration d) {
    if (d.isNegative) return '00:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.state.myPool;
    final accepted = entries.where((e) => e.needsAcknowledgement).toList();
    final inPool = entries
        .where((e) => e.isPooled && !e.needsAcknowledgement)
        .toList();
    final waiting = entries.where((e) => e.isWaiting).toList();
    final allotted = entries.where((e) => e.isAllotted).toList();

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      appBar: AppBar(
        title: const Text('Pool'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: widget.state.loadMyPool,
        child: entries.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.groups_outlined, size: 48, color: AppTheme.textTertiary),
                  SizedBox(height: 16),
                  Text(
                    'No joined sessions yet.\nJoin a session from Brands or Nearby to see it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (accepted.isNotEmpty) ...[
                    _sectionTitle('Accepted into the Pool'),
                    ...accepted.map(_acceptedCard),
                  ],
                  if (waiting.isNotEmpty) ...[
                    _sectionTitle('Waiting'),
                    ...waiting.map(_waitingCard),
                  ],
                  if (inPool.isNotEmpty) ...[
                    _sectionTitle('In the Pool'),
                    ...inPool.map(_inPoolCard),
                  ],
                  if (allotted.isNotEmpty) ...[
                    _sectionTitle('Vouchers scheduled'),
                    ...allotted.map(_allottedCard),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _card({required Widget child, Color? color, Color? border}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color ?? AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border ?? AppTheme.borderLight),
        ),
        child: child,
      );

  Widget _header(MyPoolEntry e) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.brandName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.pureBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  e.sessionTitle,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _waitingCard(MyPoolEntry e) {
    final remaining = e.acceptAt.difference(DateTime.now());
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(e),
          const SizedBox(height: 14),
          const Text(
            'Wait till somebody lets you in the Pool',
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: AppTheme.pureBlack),
              const SizedBox(width: 6),
              Text(
                _countdown(remaining),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppTheme.pureBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _acceptedCard(MyPoolEntry e) {
    final busy = _acknowledging.contains(e.id);
    final by = e.sessionCreatedBy.isNotEmpty ? e.sessionCreatedBy : e.brandName;
    return _card(
      color: AppTheme.pureBlack,
      border: AppTheme.pureBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            e.brandName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.pureWhite,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$by has accepted your request to join the Pool.',
            style: const TextStyle(fontSize: 14, color: AppTheme.pureWhite),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : () => _acknowledge(e),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pureWhite,
                foregroundColor: AppTheme.pureBlack,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                busy ? 'Please wait…' : 'Okay',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inPoolCard(MyPoolEntry e) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(e),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: AppTheme.pureBlack),
                SizedBox(width: 6),
                Text(
                  'You are in the Pool',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureBlack,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _allottedCard(MyPoolEntry e) {
    final release = e.releaseAt;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(e),
          const SizedBox(height: 12),
          Text(
            e.tierLabel != null ? '${e.tierLabel} · ${e.discountValue}' : e.discountValue,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.pureBlack,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                release == null
                    ? 'Release time to be announced'
                    : 'Releases on ${formatPoolDateTime(release)}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
