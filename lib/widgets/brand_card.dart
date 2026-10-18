import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/brand_model.dart';
import '../models/session_model.dart';
import '../theme/app_theme.dart';
import 'swipable_gallery.dart';

class BrandCard extends StatelessWidget {
  final BrandModel brand;
  final SessionModel? session;
  final VoidCallback onJoinSession;
  final VoidCallback onViewDetails;

  const BrandCard({
    super.key,
    required this.brand,
    this.session,
    required this.onJoinSession,
    required this.onViewDetails,
  });

  Future<void> _launchExternalUrl(BuildContext context, String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $urlString'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL: $urlString'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  IconData _getSocialIcon(String platform) {
    final lower = platform.toLowerCase();
    if (lower.contains('insta')) return Icons.camera_alt_outlined;
    if (lower.contains('x') || lower.contains('twit')) return Icons.alternate_email;
    if (lower.contains('link')) return Icons.business_center_outlined;
    if (lower.contains('you')) return Icons.play_circle_outline;
    return Icons.link;
  }

  @override
  Widget build(BuildContext context) {
    final creatorName = session?.sessionCreatedBy ?? brand.sessionCreatedBy;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Swipable Image Gallery
          Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                SwipableGallery(
                  images: brand.showcaseImages,
                  height: 220,
                  borderRadius: BorderRadius.circular(16),
                ),
                // Session Creator Tag
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.pureBlack.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 12, color: AppTheme.pureWhite),
                        const SizedBox(width: 5),
                        Text(
                          'Session created by: $creatorName',
                          style: const TextStyle(
                            color: AppTheme.pureWhite,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Brand Identity & Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    brand.logoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 48,
                      height: 48,
                      color: AppTheme.surfaceLight,
                      child: const Icon(Icons.storefront, color: AppTheme.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Brand Name & Tagline
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              brand.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.pureBlack,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: const Text(
                              'VERIFIED PARTNER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        brand.tagline,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Website, Social Icons, and Contact Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Brand Website Button
                InkWell(
                  onTap: () => _launchExternalUrl(context, brand.websiteUrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.language, size: 14, color: AppTheme.pureBlack),
                        SizedBox(width: 6),
                        Text(
                          'Visit Website',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.pureBlack,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_outward, size: 12, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Social Icons Row
                ...brand.socialLinks.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => _launchExternalUrl(context, entry.value),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Icon(
                          _getSocialIcon(entry.key),
                          size: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Contact info popover trigger
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppTheme.pureWhite,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${brand.name} • Contact',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.email_outlined, color: AppTheme.pureBlack),
                              title: const Text('Email'),
                              subtitle: Text(brand.contactEmail),
                              contentPadding: EdgeInsets.zero,
                              onTap: () => _launchExternalUrl(ctx, 'mailto:${brand.contactEmail}'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.phone_outlined, color: AppTheme.pureBlack),
                              title: const Text('Phone'),
                              subtitle: Text(brand.contactPhone),
                              contentPadding: EdgeInsets.zero,
                              onTap: () => _launchExternalUrl(ctx, 'tel:${brand.contactPhone}'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: const Icon(Icons.mail_outline, size: 15, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Divider(height: 1, color: AppTheme.borderLight),

          // 4. Session Action Bar (Generative Session)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.pureBlack,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'TODAY\'S ACTIVE SESSION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session != null ? session!.discountValue : 'Exclusive Vouchers',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.pureBlack,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onJoinSession,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('Join Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pureBlack,
                    foregroundColor: AppTheme.pureWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
