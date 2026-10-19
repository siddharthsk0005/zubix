import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voucher_model.dart';

class VouchersNotifier extends Notifier<List<VoucherModel>> {
  @override
  List<VoucherModel> build() {
    return [];
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
