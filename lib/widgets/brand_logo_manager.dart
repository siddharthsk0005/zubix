import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

const _maxLogoBytes = 2 * 1024 * 1024;

const _logoMimeByExtension = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

/// Lets a brand set or remove the logo shown to customers on the Brands page.
class BrandLogoManager extends StatefulWidget {
  final String brandId;

  const BrandLogoManager({super.key, required this.brandId});

  @override
  State<BrandLogoManager> createState() => _BrandLogoManagerState();
}

class _BrandLogoManagerState extends State<BrandLogoManager> {
  String _logoUrl = '';
  bool _loading = true;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final brands = await ApiService.getBrands(approvedOnly: false);
      final match = brands?.where((b) => b.id == widget.brandId);
      if (mounted && match != null && match.isNotEmpty) {
        setState(() => _logoUrl = match.first.logoUrl);
      }
    } catch (_) {
      // Keep the placeholder; the upload button still works.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Choose a logo',
      type: FileType.custom,
      allowedExtensions: _logoMimeByExtension.keys.toList(),
    );
    if (result.isEmpty) return;
    final file = result.first;
    final mime = _logoMimeByExtension[(file.extension ?? '').toLowerCase()];

    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      if (mime == null) {
        throw Exception('Use a JPG, PNG or WEBP image for the logo.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxLogoBytes) {
        throw Exception('Logo must be 2 MB or smaller.');
      }
      final url = await ApiService.uploadBrandLogo(
        widget.brandId,
        mimeType: mime,
        bytes: bytes,
      );
      if (mounted) {
        setState(() {
          _logoUrl = url;
          _status = 'Logo updated.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await ApiService.removeBrandLogo(widget.brandId);
      if (mounted) {
        setState(() {
          _logoUrl = '';
          _status = 'Logo removed.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = _logoUrl.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Brand logo',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const Text(
          'Shown next to your brand name on the Brands page. JPG, PNG or WEBP, up to 2 MB.',
          style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 72,
                color: AppTheme.surfaceLight,
                child: _loading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : hasLogo
                        ? Image.network(
                            _logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                const Icon(Icons.storefront, color: AppTheme.textPrimary),
                          )
                        : const Icon(Icons.storefront, color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _busy || _loading ? null : _pickAndUpload,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text(hasLogo ? 'Replace logo' : 'Upload logo'),
            ),
            if (hasLogo) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _busy ? null : _remove,
                child: const Text('Remove'),
              ),
            ],
          ],
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_status!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ),
      ],
    );
  }
}
