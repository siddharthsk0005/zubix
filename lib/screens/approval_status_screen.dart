import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

// Shown after a customer submits their profile until an admin approves or rejects the sign-up.
class ApprovalStatusScreen extends ConsumerStatefulWidget {
  const ApprovalStatusScreen({super.key});

  @override
  ConsumerState<ApprovalStatusScreen> createState() =>
      _ApprovalStatusScreenState();
}

class _ApprovalStatusScreenState extends ConsumerState<ApprovalStatusScreen> {
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);
    await ref.read(authProvider.notifier).refreshApprovalStatus();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final rejected = user?.approvalStatus == 'rejected';
    final location = [
      user?.district,
      user?.state,
      user?.country,
    ].where((v) => v != null && v.isNotEmpty).join(', ');

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    rejected
                        ? Icons.cancel_outlined
                        : Icons.hourglass_top_rounded,
                    size: 64,
                    color: AppTheme.pureBlack,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    rejected
                        ? 'Registration not approved'
                        : 'Awaiting admin approval',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rejected
                        ? 'Your Zubix registration was not approved. Please contact Zubix support.'
                        : 'Your profile is submitted. Zubix will review it and notify you here once it is approved.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow('Name', user?.name ?? user?.displayName),
                        _detailRow('Mobile', user?.phone),
                        _detailRow('Email', user?.email),
                        _detailRow('Location', location),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!rejected)
                    ElevatedButton(
                      onPressed: _checking ? null : _check,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pureBlack,
                        foregroundColor: AppTheme.pureWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _checking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.pureWhite,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Check status'),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.pureBlack,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value == null || value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
