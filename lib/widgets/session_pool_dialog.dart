import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/session_pool_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SessionPoolDialog extends StatefulWidget {
  final SessionModel session;
  final String brandName;
  final ValueChanged<SessionModel> onUpdated;

  const SessionPoolDialog({
    super.key,
    required this.session,
    required this.brandName,
    required this.onUpdated,
  });

  @override
  State<SessionPoolDialog> createState() => _SessionPoolDialogState();
}

class _TierDraft {
  final TextEditingController label;
  final TextEditingController slots;
  final TextEditingController discount;

  _TierDraft({required String label, required String slots, required String discount})
      : label = TextEditingController(text: label),
        slots = TextEditingController(text: slots),
        discount = TextEditingController(text: discount);

  void dispose() {
    label.dispose();
    slots.dispose();
    discount.dispose();
  }
}

class _SessionPoolDialogState extends State<SessionPoolDialog> {
  late SessionModel _session;
  SessionPoolData? _data;
  bool _loading = true;
  bool _busy = false;
  String? _notice;
  bool _noticeIsError = false;

  late final TextEditingController _waitCtrl;
  DateTime? _releaseAt;
  final List<_TierDraft> _tierDrafts = [];
  bool _draftsReady = false;

  // userId -> tierKey. A user can be ticked under one tier only.
  final Map<String, String> _selection = {};

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _waitCtrl = TextEditingController(text: '${_session.waitingDurationSeconds}');
    _releaseAt = _session.poolReleaseAt;
    _load();
  }

  @override
  void dispose() {
    _waitCtrl.dispose();
    for (final d in _tierDrafts) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getSessionPool(_session.id);
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _loading = false;
        _notice = 'Could not load the pool. Check that the API is running.';
        _noticeIsError = true;
      });
      return;
    }
    setState(() {
      _data = data;
      _loading = false;
      if (!_draftsReady) {
        _draftsReady = true;
        for (final t in data.tiers) {
          _tierDrafts.add(_TierDraft(
            label: t.label,
            slots: '${t.slots}',
            discount: '${t.discountPct}',
          ));
        }
      }
      final pooled = data.participants
          .where((p) => p.status == 'pooled')
          .map((p) => p.userId)
          .toSet();
      _selection.removeWhere((userId, _) => !pooled.contains(userId));
    });
    _pushSession();
  }

  int get _allottedTotal =>
      _data?.participants.where((p) => p.status == 'allotted').length ?? 0;

  void _pushSession() {
    _session = _session.copyWith(
      poolReleaseAt: _releaseAt,
      couponTiers: _data?.tiers ?? _session.couponTiers,
      claimedVouchersCount: _allottedTotal,
    );
    widget.onUpdated(_session);
  }

  Future<void> _run(
    Future<String?> Function() action, {
    String? successMsg,
    Future<void> Function()? onOk,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    final err = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _notice = err ?? successMsg;
      _noticeIsError = err != null;
    });
    if (err == null && onOk != null) {
      await onOk();
    } else {
      await _load();
    }
  }

  Future<void> _saveSettings() async {
    final secs = int.tryParse(_waitCtrl.text.trim());
    if (secs == null || secs < 0) {
      setState(() {
        _notice = 'Enter a valid waiting time in seconds';
        _noticeIsError = true;
      });
      return;
    }
    _session = _session.copyWith(waitingDurationSeconds: secs);
    await _run(
      () => ApiService.updateSessionPool(
        _session.id,
        waitingDurationSeconds: secs,
        poolReleaseAt: _releaseAt,
      ),
      successMsg: 'Pool settings saved',
    );
  }

  Future<void> _pickReleaseAt() async {
    final initial = _releaseAt ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _releaseAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _saveTiers() async {
    final tiers = <PoolCouponTier>[];
    for (var i = 0; i < _tierDrafts.length; i++) {
      final d = _tierDrafts[i];
      final label = d.label.text.trim();
      final slots = int.tryParse(d.slots.text.trim());
      final discount = int.tryParse(d.discount.text.trim()) ?? 0;
      if (label.isEmpty || slots == null || slots < 0) {
        setState(() {
          _notice = 'Each coupon tier needs a name and a valid slot count';
          _noticeIsError = true;
        });
        return;
      }
      tiers.add(PoolCouponTier(key: '$i', label: label, slots: slots, discountPct: discount));
    }
    await _run(
      () => ApiService.updateSessionPool(_session.id, couponTiers: tiers),
      successMsg: 'Coupon tiers saved',
    );
  }

  void _addTierDraft() {
    setState(() {
      _tierDrafts.add(_TierDraft(label: '', slots: '', discount: '0'));
    });
  }

  void _removeTierDraft(int index) {
    setState(() {
      _tierDrafts.removeAt(index).dispose();
    });
  }

  int _pickedCount(String tierKey) =>
      _selection.values.where((v) => v == tierKey).length;

  void _toggle(PoolParticipant p, PoolCouponTier tier, bool? value) {
    setState(() {
      if (value == true) {
        if (_pickedCount(tier.key) >= tier.slotsLeft) {
          _notice = '${tier.label} has no free slots left';
          _noticeIsError = true;
          return;
        }
        _selection[p.userId] = tier.key;
      } else {
        _selection.remove(p.userId);
      }
    });
  }

  void _selectAll(PoolCouponTier tier, List<PoolParticipant> visible) {
    setState(() {
      final allChecked =
          visible.every((p) => _selection[p.userId] == tier.key);
      if (allChecked) {
        for (final p in visible) {
          _selection.remove(p.userId);
        }
        return;
      }
      var room = tier.slotsLeft - _pickedCount(tier.key);
      var capped = false;
      for (final p in visible) {
        if (_selection.containsKey(p.userId)) continue;
        if (room <= 0) {
          capped = true;
          break;
        }
        _selection[p.userId] = tier.key;
        room--;
      }
      if (capped) {
        _notice = 'Only ${tier.slotsLeft} slots in ${tier.label}; selected as many as fit';
        _noticeIsError = true;
      }
    });
  }

  Future<void> _allot(PoolCouponTier tier) async {
    final ids = _selection.entries
        .where((e) => e.value == tier.key)
        .map((e) => e.key)
        .toList();
    if (ids.isEmpty) return;
    await _run(
      () => ApiService.allotSessionVouchers(
        _session.id,
        tierKey: tier.key,
        userIds: ids,
      ),
      successMsg: 'Allotted ${ids.length} to ${tier.label}',
      onOk: () async {
        _selection.removeWhere((_, v) => v == tier.key);
        await _load();
      },
    );
  }

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Widget _sectionTitle(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppTheme.textSecondary,
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: child,
      );

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );

  Widget _settingsCard() {
    final locked = _allottedTotal > 0;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Timing'),
          const SizedBox(height: 10),
          TextField(
            controller: _waitCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Waiting timer (seconds)',
              helperText: 'Users who join are accepted into the pool after this time',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickReleaseAt,
                  icon: const Icon(Icons.schedule, size: 16),
                  label: Text(
                    _releaseAt == null
                        ? 'Pick voucher release time'
                        : 'Releases ${_fmt(_releaseAt!)}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _busy ? null : _saveSettings,
                child: const Text('Save'),
              ),
            ],
          ),
          if (locked)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Vouchers already allotted keep their original release time.',
                style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tiersEditor() {
    final locked = _allottedTotal > 0;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Coupon tiers'),
          const SizedBox(height: 10),
          if (_tierDrafts.isEmpty)
            const Text(
              'No coupon tiers yet. Add one to start allotting.',
              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
            ),
          for (var i = 0; i < _tierDrafts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _tierDrafts[i].label,
                      enabled: !locked,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _tierDrafts[i].slots,
                      enabled: !locked,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Slots'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _tierDrafts[i].discount,
                      enabled: !locked,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Off %'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove tier',
                    onPressed: locked ? null : () => _removeTierDraft(i),
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              TextButton.icon(
                onPressed: locked ? null : _addTierDraft,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add tier'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: (_busy || locked) ? null : _saveTiers,
                child: const Text('Save tiers'),
              ),
            ],
          ),
          if (locked)
            const Text(
              'Tiers are locked after vouchers are allotted.',
              style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _tierSection(PoolCouponTier tier, List<PoolParticipant> pooled) {
    final visible = pooled
        .where((p) => _selection[p.userId] == null || _selection[p.userId] == tier.key)
        .toList();
    final picked = _pickedCount(tier.key);
    final room = tier.slotsLeft - picked;
    final allChecked =
        visible.isNotEmpty && visible.every((p) => _selection[p.userId] == tier.key);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tier.label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              _chip('${tier.discountPct}% OFF'),
              const SizedBox(width: 6),
              _chip('${tier.allottedCount}/${tier.slots} allotted'),
              const SizedBox(width: 6),
              _chip('$room left'),
            ],
          ),
          const SizedBox(height: 6),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No pooled users available for this tier.',
                style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
              ),
            )
          else ...[
            Row(
              children: [
                Checkbox(
                  value: allChecked,
                  onChanged: (_) => _selectAll(tier, visible),
                ),
                const Text('Select all', style: TextStyle(fontSize: 13)),
                const Spacer(),
                ElevatedButton(
                  onPressed: (picked == 0 || _busy) ? null : () => _allot(tier),
                  child: Text('Allot $picked'),
                ),
              ],
            ),
            for (final p in visible)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _selection[p.userId] == tier.key,
                onChanged: (_selection[p.userId] != tier.key && room <= 0)
                    ? null
                    : (v) => _toggle(p, tier, v),
                title: Text(p.name, style: const TextStyle(fontSize: 13)),
                subtitle: (p.phone ?? p.email) == null
                    ? null
                    : Text(p.phone ?? p.email!, style: const TextStyle(fontSize: 11)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _statusList(String title, List<PoolParticipant> items, String Function(PoolParticipant) trailing) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('$title (${items.length})'),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'None',
              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
            )
          else
            for (final p in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(p.name, style: const TextStyle(fontSize: 13)),
                    ),
                    Text(
                      trailing(p),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _body() {
    final data = _data;
    if (_loading && data == null) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (data == null) {
      return const SizedBox.shrink();
    }

    final pooled = data.participants.where((p) => p.status == 'pooled').toList();
    final waiting = data.participants.where((p) => p.status == 'waiting').toList();
    final allotted = data.participants.where((p) => p.status == 'allotted').toList();
    final tierById = {for (final t in data.tiers) t.key: t};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _chip('${waiting.length} waiting'),
            const SizedBox(width: 6),
            _chip('${pooled.length} in pool'),
            const SizedBox(width: 6),
            _chip('${allotted.length} allotted'),
          ],
        ),
        const SizedBox(height: 14),
        _settingsCard(),
        const SizedBox(height: 12),
        _tiersEditor(),
        const SizedBox(height: 16),
        _sectionTitle('Allot pool to coupon tiers'),
        const SizedBox(height: 8),
        if (data.tiers.isEmpty)
          _card(
            child: const Text(
              'Add coupon tiers above before allotting vouchers.',
              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
            ),
          )
        else
          for (final t in data.tiers) ...[
            _tierSection(t, pooled),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 6),
        _statusList(
          'Allotted',
          allotted,
          (p) => tierById[p.tierKey]?.label ?? '',
        ),
        const SizedBox(height: 10),
        _statusList(
          'Waiting',
          waiting,
          (p) => p.acceptAt == null ? '' : 'Accepts ${_fmt(p.acceptAt!.toLocal())}',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage pool',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          widget.brandName,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              if (_notice != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _noticeIsError
                        ? Colors.red.shade50
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _notice!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _noticeIsError ? Colors.red.shade800 : AppTheme.textPrimary,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(child: _body()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
