import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/voucher_ticket.dart';

class VouchersScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onExploreBrands;

  const VouchersScreen({
    super.key,
    required this.state,
    required this.onExploreBrands,
  });

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final allVouchers = widget.state.myVouchers;
    final activeVouchers = allVouchers.where((v) => !v.isRedeemed).toList();
    final usedVouchers = allVouchers.where((v) => v.isRedeemed).toList();

    List<dynamic> displayedVouchers;
    if (_selectedFilter == 'Active') {
      displayedVouchers = activeVouchers;
    } else if (_selectedFilter == 'Used') {
      displayedVouchers = usedVouchers;
    } else {
      displayedVouchers = allVouchers;
    }

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      appBar: AppBar(
        title: const Text('My Vouchers'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Wallet Summary Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.pureBlack,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ZUBIX DIGITAL WALLET',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${activeVouchers.length} Active Vouchers',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppTheme.pureWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready to use for instant discounts on partner brand websites.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filter Pills
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: ['All', 'Active', 'Used'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.pureWhite
                              : AppTheme.pureBlack,
                        ),
                      ),
                      selectedColor: AppTheme.pureBlack,
                      backgroundColor: AppTheme.surfaceLight,
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.pureBlack
                            : AppTheme.borderLight,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Vouchers List
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: displayedVouchers.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.card_giftcard_outlined,
                            size: 54,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Vouchers in this Section',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Join a Generative Session to win instant brand vouchers.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: widget.onExploreBrands,
                            child: const Text('Explore Brands'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final voucher = displayedVouchers[index];
                      return VoucherTicket(
                        voucher: voucher,
                        onRedeemToggle: () {
                          widget.state.markVoucherRedeemed(voucher.id);
                        },
                      );
                    }, childCount: displayedVouchers.length),
                  ),
          ),
        ],
      ),
    );
  }
}
