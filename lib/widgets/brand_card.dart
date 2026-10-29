import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/brand_model.dart';
import '../models/session_model.dart';
import '../models/social_channel.dart';
import '../theme/app_theme.dart';
import 'brand_media_gallery.dart';
import 'swipable_gallery.dart';

class BrandCard extends StatelessWidget {
  final BrandModel brand;
  final String? categoryName;
  final SessionModel? session;
  final bool joined;
  final VoidCallback onJoinSession;
  final VoidCallback onViewDetails;

  const BrandCard({
    super.key,
    required this.brand,
    this.categoryName,
    this.session,
    this.joined = false,
    required this.onJoinSession,
    required this.onViewDetails,
  });

  // Saved websites are often entered without a scheme (e.g. www.brand.com).
  String _withScheme(String url) {
    final v = url.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return 'https://$v';
  }

  Future<void> _launchExternalUrl(BuildContext context, String urlString) async {
    // No canLaunchUrl gate: on web it breaks the tap's user gesture, and on Android it returns false without manifest <queries>.
    final uri = Uri.tryParse(urlString);
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $urlString'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: brand.media.isNotEmpty
                ? BrandMediaGallery(
                    items: brand.media,
                    height: 220,
                    borderRadius: BorderRadius.circular(16),
                  )
                : SwipableGallery(
                    images: brand.showcaseImages,
                    height: 220,
                    borderRadius: BorderRadius.circular(16),
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
                          const SizedBox(width: 6),
                          const Tooltip(
                            message: 'Verified partner',
                            child: Icon(
                              Icons.verified,
                              size: 18,
                              color: Color(0xFF1D9BF0),
                            ),
                          ),
                        ],
                      ),
                      if (categoryName != null && categoryName!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          categoryName!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                  onTap: () => _launchExternalUrl(context, _withScheme(brand.websiteUrl)),
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

                // Channel logos; each opens its link.
                ...socialChannels.where((c) => (brand.socialLinks[c.key] ?? '').trim().isNotEmpty).map((channel) {
                  final value = brand.socialLinks[channel.key]!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Tooltip(
                      message: channel.label,
                      child: InkWell(
                        onTap: () {
                          final uri = socialChannelUri(channel.key, value);
                          if (uri != null) _launchExternalUrl(context, uri.toString());
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Center(
                            child: FaIcon(channel.icon, size: 15, color: channel.color),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

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
                          Text(
                            'SESSION BY ${(session?.sessionCreatedBy ?? brand.sessionCreatedBy).trim().toUpperCase()}',
                            style: const TextStyle(
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
                  onPressed: joined ? null : onJoinSession,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('Join Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pureBlack,
                    foregroundColor: AppTheme.pureWhite,
                    disabledBackgroundColor: AppTheme.borderLight,
                    disabledForegroundColor: AppTheme.textTertiary,
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
