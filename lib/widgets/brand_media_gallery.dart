import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/brand_media_model.dart';
import '../theme/app_theme.dart';

/// Shows a brand's uploaded images and videos in the order the brand set.
class BrandMediaGallery extends StatefulWidget {
  final List<BrandMediaItem> items;
  final double height;
  final BorderRadius? borderRadius;

  const BrandMediaGallery({
    super.key,
    required this.items,
    this.height = 220,
    this.borderRadius,
  });

  @override
  State<BrandMediaGallery> createState() => _BrandMediaGalleryState();
}

class _BrandMediaGalleryState extends State<BrandMediaGallery> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final item = items[i];
                if (item.isVideo) {
                  return _BrandVideoPage(
                    key: ValueKey(item.id),
                    url: item.url,
                    isActive: i == _index,
                  );
                }
                return Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: widget.height,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stack) => const Center(
                    child: Icon(Icons.broken_image_outlined, color: AppTheme.textTertiary, size: 40),
                  ),
                );
              },
            ),
            if (items.length > 1)
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.pureBlack.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1}/${items.length}',
                    style: const TextStyle(color: AppTheme.pureWhite, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandVideoPage extends StatefulWidget {
  final String url;
  final bool isActive;

  const _BrandVideoPage({super.key, required this.url, required this.isActive});

  @override
  State<_BrandVideoPage> createState() => _BrandVideoPageState();
}

class _BrandVideoPageState extends State<_BrandVideoPage> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _showIcon = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (!mounted) return;
      // Muted so browsers and phones allow autoplay; looping keeps the brand's reel moving.
      _controller.setVolume(0);
      _controller.setLooping(true);
      setState(() => _ready = true);
      _syncPlayback();
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void didUpdateWidget(covariant _BrandVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) _syncPlayback();
  }

  void _syncPlayback() {
    if (!_ready) return;
    if (widget.isActive) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  void _togglePlay() {
    if (!_ready) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
      _showIcon = true;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showIcon = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Icon(Icons.videocam_off_outlined, color: AppTheme.textTertiary, size: 40),
      );
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final playing = _controller.value.isPlaying;
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          Center(
            child: AnimatedOpacity(
              opacity: _showIcon || !playing ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.pureBlack.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: AppTheme.pureWhite,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
