import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/voucher_model.dart';
import '../theme/app_theme.dart';

class VoucherTicket extends StatelessWidget {
  final VoucherModel voucher;
  final VoidCallback onRedeemToggle;

  const VoucherTicket({
    super.key,
    required this.voucher,
    required this.onRedeemToggle,
  });

  Future<void> _launchStore(BuildContext context) async {
    try {
      final uri = Uri.parse(voucher.brandWebsite);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${voucher.brandWebsite}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Store URL: ${voucher.brandWebsite}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: voucher.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.pureWhite, size: 18),
            const SizedBox(width: 8),
            Text('Coupon code "${voucher.code}" copied to clipboard!'),
          ],
        ),
        backgroundColor: AppTheme.pureBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = DateTime.now().isAfter(voucher.expiresAt);
    final daysRemaining = voucher.expiresAt.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: voucher.isRedeemed ? AppTheme.surfaceLight : AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: voucher.isRedeemed ? AppTheme.borderLight : AppTheme.pureBlack,
          width: voucher.isRedeemed ? 1.0 : 1.4,
        ),
        boxShadow: voucher.isRedeemed
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section: Brand & Discount
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    voucher.brandLogoUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 44,
                      height: 44,
                      color: AppTheme.surfaceLight,
                      child: const Icon(Icons.card_giftcard, color: AppTheme.pureBlack),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              voucher.brandName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.pureBlack,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: voucher.isRedeemed ? AppTheme.surfaceMuted : AppTheme.pureBlack,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              voucher.isRedeemed ? 'USED' : 'ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: voucher.isRedeemed ? AppTheme.textSecondary : AppTheme.pureWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.discountValue,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppTheme.pureBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Category: ${voucher.categoryName}',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Perforated Divider
          Row(
            children: [
              Container(
                width: 12,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                  border: Border(
                    right: BorderSide(color: AppTheme.borderLight),
                    top: BorderSide(color: AppTheme.borderLight),
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boxWidth = constraints.constrainWidth();
                    const dashWidth = 6.0;
                    const dashSpace = 4.0;
                    final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
                    return Flex(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      direction: Axis.horizontal,
                      children: List.generate(dashCount, (_) {
                        return const SizedBox(
                          width: dashWidth,
                          height: 1.2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: AppTheme.borderLight),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              Container(
                width: 12,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                  border: Border(
                    left: BorderSide(color: AppTheme.borderLight),
                    top: BorderSide(color: AppTheme.borderLight),
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
              ),
            ],
          ),

          // Bottom section: Code Box & Actions
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Coupon Code Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VOUCHER CODE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              voucher.code,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppTheme.pureBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _copyCode(context),
                        icon: const Icon(Icons.copy, size: 14, color: AppTheme.pureBlack),
                        label: const Text(
                          'COPY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.pureBlack,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.pureWhite,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: AppTheme.borderLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Expiry and Action buttons
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 13,
                      color: isExpired ? Colors.red : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isExpired ? 'Expired' : 'Expires in $daysRemaining days',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isExpired ? Colors.red : AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    // Shop on Website Button
                    ElevatedButton.icon(
                      onPressed: () => _launchStore(context),
                      icon: const Icon(Icons.open_in_browser, size: 14),
                      label: const Text('Shop Online'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pureBlack,
                        foregroundColor: AppTheme.pureWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
