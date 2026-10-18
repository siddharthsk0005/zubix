import 'package:flutter/material.dart';
import '../models/brand_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/swipable_gallery.dart';

class BrandPartnerDashboard extends StatefulWidget {
  final AppState state;

  const BrandPartnerDashboard({super.key, required this.state});

  @override
  State<BrandPartnerDashboard> createState() => _BrandPartnerDashboardState();
}

class _BrandPartnerDashboardState extends State<BrandPartnerDashboard> {
  late BrandModel _selectedBrand;
  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _bioController;
  late TextEditingController _websiteController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.state.brands.first;
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _selectedBrand.name);
    _taglineController = TextEditingController(text: _selectedBrand.tagline);
    _bioController = TextEditingController(text: _selectedBrand.bio);
    _websiteController = TextEditingController(text: _selectedBrand.websiteUrl);
    _emailController = TextEditingController(text: _selectedBrand.contactEmail);
    _phoneController = TextEditingController(text: _selectedBrand.contactPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = widget.state.sessions.where((s) => s.brandId == _selectedBrand.id).toList();
    final totalClaims = sessions.fold<int>(0, (sum, s) => sum + s.claimedVouchersCount);

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      appBar: AppBar(
        title: const Text('Brand Partner Portal'),
        actions: [
          DropdownButton<String>(
            value: _selectedBrand.id,
            underline: const SizedBox.shrink(),
            items: widget.state.brands.map((b) {
              return DropdownMenuItem(
                value: b.id,
                child: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              );
            }).toList(),
            onChanged: (brandId) {
              if (brandId != null) {
                setState(() {
                  _selectedBrand = widget.state.brands.firstWhere((b) => b.id == brandId);
                  _initControllers();
                });
              }
            },
          ),
          const SizedBox(width: 16),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Partner Header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _selectedBrand.logoUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.store),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedBrand.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _selectedBrand.tagline,
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _selectedBrand.isApproved ? AppTheme.pureBlack : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedBrand.isApproved ? 'ACTIVE ECOSYSTEM PARTNER' : 'PENDING APPROVAL',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: _selectedBrand.isApproved ? AppTheme.pureWhite : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Performance Analytics Grid
            const Text(
              'BRAND PERFORMANCE METRICS',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetricCard('Generative Sessions', '${sessions.length}', Icons.bolt),
                const SizedBox(width: 12),
                _buildMetricCard('Vouchers Unlocked', '$totalClaims', Icons.card_giftcard),
                const SizedBox(width: 12),
                _buildMetricCard('Store Clicks', '${totalClaims * 14}', Icons.touch_app),
              ],
            ),

            const SizedBox(height: 32),

            // Showcase Images Preview
            const Text(
              'SWIPABLE LOOKBOOK SHOWCASE',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            SwipableGallery(
              images: _selectedBrand.showcaseImages,
              height: 220,
              borderRadius: BorderRadius.circular(16),
            ),

            const SizedBox(height: 32),

            // Profile Edit Form
            const Text(
              'BRAND PROFILE & SOCIAL INFORMATION',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Brand Name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _taglineController,
              decoration: const InputDecoration(labelText: 'Tagline'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Brand Bio / Story'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Official Website URL'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Contact Email'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Contact Phone'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                _selectedBrand.name = _nameController.text.trim();
                _selectedBrand.tagline = _taglineController.text.trim();
                _selectedBrand.bio = _bioController.text.trim();
                _selectedBrand.websiteUrl = _websiteController.text.trim();
                _selectedBrand.contactEmail = _emailController.text.trim();
                _selectedBrand.contactPhone = _phoneController.text.trim();

                widget.state.updateBrand(_selectedBrand);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Brand Profile Updated Successfully!'),
                    backgroundColor: AppTheme.pureBlack,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save Profile Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppTheme.pureBlack),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.pureBlack),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
