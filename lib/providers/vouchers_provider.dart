import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voucher_model.dart';

class VouchersNotifier extends Notifier<List<VoucherModel>> {
  @override
  List<VoucherModel> build() {
    return [
      VoucherModel(
        id: 'vouch_seed_01',
        code: 'ZUBIX-AURORA-WELCOME',
        brandName: 'AURORA Minimal',
        brandLogoUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=200&auto=format&fit=crop&q=80',
        brandWebsite: 'https://auroraminimal.example.com',
        discountValue: '20% OFF',
        categoryName: 'Fashion and Lifestyle',
        claimedAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
        terms: 'Minimum cart value \$80. Free shipping included.',
      ),
    ];
  }

  void addVoucher(VoucherModel voucher) {
    state = [voucher, ...state];
  }

  void markRedeemed(String voucherId) {
    state = state.map((v) {
      if (v.id == voucherId) {
        v.isRedeemed = true;
      }
      return v;
    }).toList();
  }
}

final vouchersProvider = NotifierProvider<VouchersNotifier, List<VoucherModel>>(
  VouchersNotifier.new,
);

final activeVouchersCountProvider = Provider<int>((ref) {
  final vouchers = ref.watch(vouchersProvider);
  return vouchers.where((v) => !v.isRedeemed).length;
});
