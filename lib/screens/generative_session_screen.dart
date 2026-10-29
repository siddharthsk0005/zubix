import 'dart:async';

import 'package:flutter/material.dart';

import '../models/my_pool_model.dart';
import '../screens/pool_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

// Shows the customer's server-side status for the session they joined.
class GenerativeSessionScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onNavigateToPool;
  final VoidCallback onNavigateToVouchers;

  const GenerativeSessionScreen({
    super.key,
    required this.state,
    required this.onNavigateToPool,
    required this.onNavigateToVouchers,
  });

  @override
  Widget build(BuildContext context) {
    final sessionId = state.activeParticipatingSession?.id;
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      appBar: AppBar(
        title: const Text('Generative Session'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: sessionId == null
          ? const Center(child: Text('You are not in a session.'))
          : _JoinedSessionView(
              state: state,
              sessionId: sessionId,
              onNavigateToPool: onNavigateToPool,
              onNavigateToVouchers: onNavigateToVouchers,
            ),
    );
  }
}

class _JoinedSessionView extends StatefulWidget {
  final AppState state;
  final String sessionId;
  final VoidCallback onNavigateToPool;
  final VoidCallback onNavigateToVouchers;

  const _JoinedSessionView({
    required this.state,
    required this.sessionId,
    required this.onNavigateToPool,
    required this.onNavigateToVouchers,
  });

  @override
  State<_JoinedSessionView> createState() => _JoinedSessionViewState();
}

class _JoinedSessionViewState extends State<_JoinedSessionView> {
  Timer? _ticker;
  int _ticks = 0;
  bool _loaded = false;
  bool _acknowledging = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _ticks++;
      if (_ticks % 5 == 0) _refresh();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await widget.state.loadMyPool();
      if (mounted) setState(() => _loaded = true);
    } catch (_) {
      // Keep the spinner until a later refresh succeeds.
    }
  }

  Future<void> _acknowledge(MyPoolEntry entry) async {
    setState(() => _acknowledging = true);
    final error = await widget.state.acknowledgePoolEntry(entry.id);
    if (!mounted) return;
    setState(() => _acknowledging = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    } else {
      _refresh();
    }
  }

  void _goToPool() {
    widget.state.leaveSessionRoom();
    widget.onNavigateToPool();
  }

  void _goToVouchers() {
    widget.state.leaveSessionRoom();
    widget.onNavigateToVouchers();
  }

  MyPoolEntry? _findEntry() {
    for (final e in widget.state.myPool) {
      if (e.sessionId == widget.sessionId) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.pureBlack),
      );
    }

    final entry = _findEntry();
    final Widget content;
    if (entry == null) {
      content = _releasedView();
    } else if (entry.isWaiting) {
      content = _waitingView(entry);
    } else if (entry.isAllotted) {
      content = _allottedView(entry);
    } else {
      content = _pooledView(entry);
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: content,
      ),
    );
  }

  Widget _waitingView(MyPoolEntry entry) {
    final remaining = entry.acceptAt.difference(DateTime.now());
    final left = remaining.isNegative ? Duration.zero : remaining;
    final total = entry.acceptAt.difference(entry.joinedAt).inMilliseconds;
    final progress = total <= 0
        ? 1.0
        : (1 - left.inMilliseconds / total).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                color: AppTheme.pureBlack,
                backgroundColor: AppTheme.surfaceLight,
              ),
              Text(
                _formatCountdown(left),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.pureBlack,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Wait till somebody lets you in the Pool',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.pureBlack,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'The session creator will accept your request when the timer ends. '
          'You stay in the pool even if you leave this screen.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _pooledView(MyPoolEntry entry) {
    final needsOkay = entry.needsAcknowledgement;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline,
            size: 64, color: AppTheme.pureBlack),
        const SizedBox(height: 20),
        const Text(
          "You're in the Pool",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.pureBlack,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          needsOkay
              ? 'The session creator has accepted your request. Press Okay to continue.'
              : 'Vouchers will be allotted by the session creator. '
                  'Track them under Pool.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: needsOkay
              ? (_acknowledging ? null : () => _acknowledge(entry))
              : _goToPool,
          child: Text(needsOkay ? 'Okay' : 'Go to Pool'),
        ),
      ],
    );
  }

  Widget _allottedView(MyPoolEntry entry) {
    final release = entry.releaseAt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.confirmation_number_outlined,
            size: 64, color: AppTheme.pureBlack),
        const SizedBox(height: 20),
        const Text(
          'Voucher allotted',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.pureBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.tierLabel ?? 'Voucher',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          entry.discountValue,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.pureBlack,
          ),
        ),
        if (release != null) ...[
          const SizedBox(height: 12),
          Text(
            'Releases on ${formatPoolDateTime(release)}',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _goToPool,
          child: const Text('Go to Pool'),
        ),
      ],
    );
  }

  Widget _releasedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 64, color: AppTheme.pureBlack),
        const SizedBox(height: 20),
        const Text(
          'Your voucher has been released',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.pureBlack,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'It is now available in My Vouchers.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _goToVouchers,
          child: const Text('View My Vouchers'),
        ),
      ],
    );
  }

  String _formatCountdown(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return d.inHours > 0
        ? '${d.inHours}:${two(m)}:${two(s)}'
        : '${two(m)}:${two(s)}';
  }
}
