import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SwipableGallery extends StatefulWidget {
  final List<String> images;
  final double height;
  final BorderRadius? borderRadius;

  const SwipableGallery({
    super.key,
    required this.images,
    this.height = 240,
    this.borderRadius,
  });

  @override
  State<SwipableGallery> createState() => _SwipableGalleryState();
}

class _SwipableGalleryState extends State<SwipableGallery> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullscreenViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          final modalPageController = PageController(initialPage: initialIndex);
          int modalIndex = initialIndex;

          return StatefulBuilder(
            builder: (context, setModalState) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppTheme.pureWhite,
                  elevation: 0,
                  title: Text(
                    'Lookbook (${modalIndex + 1}/${widget.images.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.pureWhite),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                body: PageView.builder(
                  controller: modalPageController,
                  itemCount: widget.images.length,
                  onPageChanged: (idx) {
                    setModalState(() => modalIndex = idx);
                  },
                  itemBuilder: (context, idx) {
                    return Center(
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 3.5,
                        child: Image.network(
                          widget.images[idx],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(color: AppTheme.pureWhite, strokeWidth: 2),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.photo_library_outlined, color: AppTheme.textTertiary, size: 40),
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
              },
              itemBuilder: (context, index) {
                final url = widget.images[index];
                return GestureDetector(
                  onTap: () => _openFullscreenViewer(context, index),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppTheme.surfaceLight,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pureBlack),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.surfaceLight,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: AppTheme.textTertiary),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Gradient shadow overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Swipable indicator dots
          if (widget.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (idx) {
                  final isSelected = idx == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isSelected ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.pureWhite : AppTheme.pureWhite.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          // Photo count badge + zoom prompt
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _openFullscreenViewer(context, _currentIndex),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.pureBlack.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fullscreen, color: AppTheme.pureWhite, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentIndex + 1}/${widget.images.length}',
                      style: const TextStyle(
                        color: AppTheme.pureWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
