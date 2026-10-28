import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/brand_media_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

const _maxImageBytes = 5 * 1024 * 1024;
const _maxVideoBytes = 20 * 1024 * 1024;

const _mimeByExtension = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'webm': 'video/webm',
};

/// Lets a brand upload, reorder and delete the images/videos customers see on the Brands page.
class BrandMediaManager extends StatefulWidget {
  final String brandId;

  const BrandMediaManager({super.key, required this.brandId});

  @override
  State<BrandMediaManager> createState() => _BrandMediaManagerState();
}

class _BrandMediaManagerState extends State<BrandMediaManager> {
  List<BrandMediaItem> _items = [];
  bool _loading = true;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.getBrandMedia(widget.brandId);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Choose images or videos',
      type: FileType.custom,
      allowedExtensions: _mimeByExtension.keys.toList(),
    );
    if (result.isEmpty) return;

    setState(() {
      _busy = true;
      _status = null;
    });
    final skipped = <String>[];
    var uploaded = 0;
    try {
      for (final file in result) {
        final ext = (file.extension ?? '').toLowerCase();
        final mime = _mimeByExtension[ext];
        if (mime == null) {
          skipped.add(file.name);
          continue;
        }
        final isVideo = mime.startsWith('video/');
        final bytes = await file.readAsBytes();
        final limit = isVideo ? _maxVideoBytes : _maxImageBytes;
        if (bytes.length > limit) {
          skipped.add(file.name);
          continue;
        }
        final item = await ApiService.uploadBrandMedia(
          widget.brandId,
          fileName: file.name,
          mimeType: mime,
          bytes: bytes,
        );
        uploaded++;
        if (mounted) setState(() => _items = [..._items, item]);
      }
      if (mounted) {
        setState(() {
          _status = skipped.isEmpty
              ? 'Uploaded $uploaded file(s).'
              : 'Uploaded $uploaded. Skipped (too large or unsupported): ${skipped.join(', ')}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final previous = _items;
    final next = [..._items];
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);
    setState(() => _items = next);
    try {
      final saved = await ApiService.reorderBrandMedia(
        widget.brandId,
        next.map((e) => e.id).toList(),
      );
      if (mounted) setState(() => _items = saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _items = previous;
          _status = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _delete(BrandMediaItem item) async {
    setState(() => _busy = true);
    try {
      await ApiService.deleteBrandMedia(widget.brandId, item.id);
      if (mounted) {
        setState(() => _items = _items.where((e) => e.id != item.id).toList());
      }
    } catch (e) {
      if (mounted) setState(() => _status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Showcase media',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            TextButton.icon(
              onPressed: _busy || _loading ? null : _upload,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const Text(
          'Customers see these in this order. Images up to 5 MB, videos up to 20 MB. Drag to reorder.',
          style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No media yet.', style: TextStyle(color: AppTheme.textTertiary)),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _items.length,
            onReorder: _busy ? (int from, int to) {} : _reorder,
            itemBuilder: (context, i) {
              final item = _items[i];
              return Container(
                key: ValueKey(item.id),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.drag_indicator, color: AppTheme.textTertiary),
                      ),
                    ),
                    Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Icon(
                      item.isVideo ? Icons.movie_outlined : Icons.image_outlined,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.isVideo ? 'Video' : 'Image',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: _busy ? null : () => _delete(item),
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                  ],
                ),
              );
            },
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
