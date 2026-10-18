import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../models/brand_model.dart';
import '../models/voucher_model.dart';
import '../services/api_service.dart';
import 'vouchers_provider.dart';
import 'categories_provider.dart';

class SessionsNotifier extends Notifier<List<SessionModel>> {
  @override
  List<SessionModel> build() {
    Future.microtask(() => fetchFromBackend());

    return [
      SessionModel(
        id: 'session_aurora_01',
        brandId: 'brand_aurora',
        sessionCreatedBy: 'Aman Verma (Admin)',
        waitingDurationSeconds: 15,
        discountValue: '35% FLAT OFF',
        couponCode: 'ZUBIX-AURORA-35',
        status: 'active',
        totalVouchersPool: 250,
        claimedVouchersCount: 84,
      ),
      SessionModel(
        id: 'session_botanica_01',
        brandId: 'brand_botanica',
        sessionCreatedBy: 'Siddharth Kumawat',
        waitingDurationSeconds: 20,
        discountValue: '25% OFF + Free Elixir',
        couponCode: 'ZUBIX-BOTANICA-25',
        status: 'active',
        totalVouchersPool: 150,
        claimedVouchersCount: 42,
      ),
      SessionModel(
        id: 'session_kanso_01',
        brandId: 'brand_kanso',
        sessionCreatedBy: 'Zubix Editorial Board',
        waitingDurationSeconds: 25,
        discountValue: '\$50 INSTANT VOUCHER',
        couponCode: 'ZUBIX-KANSO-50',
        status: 'active',
        totalVouchersPool: 100,
        claimedVouchersCount: 61,
      ),
    ];
  }

  Future<void> fetchFromBackend() async {
    try {
      final remote = await ApiService.getActiveSessions();
      if (remote != null && remote.isNotEmpty) {
        state = remote;
      }
    } catch (_) {}
  }

  void addSession(SessionModel session) {
    state = [...state, session];
  }

  void incrementClaimCount(String sessionId) {
    state = state.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(claimedVouchersCount: s.claimedVouchersCount + 1);
      }
      return s;
    }).toList();
  }
}

final sessionsProvider = NotifierProvider<SessionsNotifier, List<SessionModel>>(
  SessionsNotifier.new,
);

// ----------------------------------------------------
// ACTIVE GENERATIVE SESSION PARTICIPATION ENGINE
// ----------------------------------------------------
enum GenerativeStatus { idle, waiting, completed }

class GenerativeSessionState {
  final GenerativeStatus status;
  final SessionModel? session;
  final BrandModel? brand;
  final int remainingSeconds;
  final int totalWaitingSeconds;
  final VoucherModel? unlockedVoucher;

  const GenerativeSessionState({
    this.status = GenerativeStatus.idle,
    this.session,
    this.brand,
    this.remainingSeconds = 0,
    this.totalWaitingSeconds = 0,
    this.unlockedVoucher,
  });

  double get progress {
    if (totalWaitingSeconds == 0) return 0.0;
    return 1.0 - (remainingSeconds / totalWaitingSeconds);
  }

  GenerativeSessionState copyWith({
    GenerativeStatus? status,
    SessionModel? session,
    BrandModel? brand,
    int? remainingSeconds,
    int? totalWaitingSeconds,
    VoucherModel? unlockedVoucher,
  }) {
    return GenerativeSessionState(
      status: status ?? this.status,
      session: session ?? this.session,
      brand: brand ?? this.brand,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalWaitingSeconds: totalWaitingSeconds ?? this.totalWaitingSeconds,
      unlockedVoucher: unlockedVoucher ?? this.unlockedVoucher,
    );
  }
}

class GenerativeSessionNotifier extends Notifier<GenerativeSessionState> {
  Timer? _timer;

  @override
  GenerativeSessionState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const GenerativeSessionState();
  }

  void joinSession(SessionModel session, BrandModel brand) {
    _timer?.cancel();
    state = GenerativeSessionState(
      status: GenerativeStatus.waiting,
      session: session,
      brand: brand,
      remainingSeconds: session.waitingDurationSeconds,
      totalWaitingSeconds: session.waitingDurationSeconds,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _timer?.cancel();
        _completeSession();
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    state = const GenerativeSessionState();
  }

  void dismiss() {
    state = const GenerativeSessionState();
  }

  void _completeSession() {
    final session = state.session;
    final brand = state.brand;
    if (session == null || brand == null) return;

    ref.read(sessionsProvider.notifier).incrementClaimCount(session.id);

    final categories = ref.read(categoriesProvider);
    final categoryName = categories
        .firstWhere((c) => c.id == brand.categoryId, orElse: () => categories.first)
        .name;

    final newVoucher = VoucherModel(
      id: 'vouch_${DateTime.now().millisecondsSinceEpoch}',
      code: session.couponCode,
      brandName: brand.name,
      brandLogoUrl: brand.logoUrl,
      brandWebsite: brand.websiteUrl,
      discountValue: session.discountValue,
      categoryName: categoryName,
      claimedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 14)),
      terms: 'Official partner store discount. Redeemable at checkout.',
    );

    ref.read(vouchersProvider.notifier).addVoucher(newVoucher);

    // Persist claim in live Supabase PostgreSQL database
    ApiService.claimSessionVoucher(session.id);

    state = state.copyWith(
      status: GenerativeStatus.completed,
      remainingSeconds: 0,
      unlockedVoucher: newVoucher,
    );
  }
}

final generativeSessionProvider = NotifierProvider<GenerativeSessionNotifier, GenerativeSessionState>(
  GenerativeSessionNotifier.new,
);
