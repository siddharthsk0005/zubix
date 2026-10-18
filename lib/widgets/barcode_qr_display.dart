import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BarcodeQrDisplay extends StatefulWidget {
  final String code;
  final String brandName;
  final String discountValue;

  const BarcodeQrDisplay({
    super.key,
    required this.code,
    required this.brandName,
    required this.discountValue,
  });

  static void showModal(
    BuildContext context, {
    required String code,
    required String brandName,
    required String discountValue,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brandName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        discountValue,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              BarcodeQrDisplay(
                code: code,
                brandName: brandName,
                discountValue: discountValue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Present this code at physical boutique checkout counter for scanner validation.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  State<BarcodeQrDisplay> createState() => _BarcodeQrDisplayState();
}

class _BarcodeQrDisplayState extends State<BarcodeQrDisplay> {
  bool _showQr = true; // true: QR, false: Barcode

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          // Mode Toggle (QR vs Barcode)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _showQr = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _showQr ? AppTheme.pureBlack : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code, size: 14, color: _showQr ? AppTheme.pureWhite : AppTheme.pureBlack),
                      const SizedBox(width: 4),
                      Text(
                        'QR SCAN',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _showQr ? AppTheme.pureWhite : AppTheme.pureBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showQr = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: !_showQr ? AppTheme.pureBlack : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.view_week, size: 14, color: !_showQr ? AppTheme.pureWhite : AppTheme.pureBlack),
                      const SizedBox(width: 4),
                      Text(
                        'BARCODE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: !_showQr ? AppTheme.pureWhite : AppTheme.pureBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Render Selected Code View
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: _showQr
                ? CustomPaint(
                    size: const Size(160, 160),
                    painter: _QrCodePainter(widget.code),
                  )
                : CustomPaint(
                    size: const Size(220, 60),
                    painter: _BarcodePainter(widget.code),
                  ),
          ),

          const SizedBox(height: 12),

          Text(
            widget.code,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppTheme.pureBlack,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// CUSTOM PAINTER: DYNAMIC QR CODE PATTERN
// ----------------------------------------------------
class _QrCodePainter extends CustomPainter {
  final String text;

  _QrCodePainter(this.text);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.pureBlack
      ..style = PaintingStyle.fill;

    const int gridSize = 21; // standard QR version 1 size
    final double cellSize = size.width / gridSize;

    // Helper: draw finder pattern (three corners)
    void drawFinderPattern(double startX, double startY) {
      // 7x7 outer square
      canvas.drawRect(Rect.fromLTWH(startX, startY, 7 * cellSize, 7 * cellSize), paint);
      // 5x5 inner white
      final whitePaint = Paint()..color = AppTheme.pureWhite;
      canvas.drawRect(Rect.fromLTWH(startX + cellSize, startY + cellSize, 5 * cellSize, 5 * cellSize), whitePaint);
      // 3x3 center black
      canvas.drawRect(Rect.fromLTWH(startX + 2 * cellSize, startY + 2 * cellSize, 3 * cellSize, 3 * cellSize), paint);
    }

    // Top-Left Finder
    drawFinderPattern(0, 0);
    // Top-Right Finder
    drawFinderPattern((gridSize - 7) * cellSize, 0);
    // Bottom-Left Finder
    drawFinderPattern(0, (gridSize - 7) * cellSize);

    // Draw timing patterns
    for (int i = 8; i < gridSize - 8; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(i * cellSize, 6 * cellSize, cellSize, cellSize), paint);
        canvas.drawRect(Rect.fromLTWH(6 * cellSize, i * cellSize, cellSize, cellSize), paint);
      }
    }

    // Deterministic pseudo-data modules based on text hash
    int hash = text.hashCode;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        // Skip finder pattern zones
        final inTopLeft = r < 8 && c < 8;
        final inTopRight = r < 8 && c >= gridSize - 8;
        final inBottomLeft = r >= gridSize - 8 && c < 8;
        final onTiming = r == 6 || c == 6;

        if (inTopLeft || inTopRight || inBottomLeft || onTiming) continue;

        // Bit determination
        final bit = ((hash ^ (r * 31 + c * 17)) & 1) == 1;
        if (bit) {
          canvas.drawRect(Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) => oldDelegate.text != text;
}

// ----------------------------------------------------
// CUSTOM PAINTER: DYNAMIC 1D BARCODE
// ----------------------------------------------------
class _BarcodePainter extends CustomPainter {
  final String text;

  _BarcodePainter(this.text);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.pureBlack
      ..style = PaintingStyle.fill;

    final int hash = text.hashCode.abs();
    double currentX = 8.0;
    final double barHeight = size.height;
    final double maxWidth = size.width - 16.0;

    // Start guard
    canvas.drawRect(Rect.fromLTWH(currentX, 0, 2.0, barHeight), paint);
    currentX += 4.0;
    canvas.drawRect(Rect.fromLTWH(currentX, 0, 1.5, barHeight), paint);
    currentX += 4.0;

    // Pattern loop
    int i = 0;
    while (currentX < maxWidth - 12.0) {
      final int charCode = i < text.length ? text.codeUnitAt(i) : (hash + i);
      final double width = (charCode % 3 + 1) * 1.5;
      final double gap = ((charCode >> 1) % 2 + 1) * 2.0;

      canvas.drawRect(Rect.fromLTWH(currentX, 0, width, barHeight), paint);
      currentX += width + gap;
      i++;
    }

    // Stop guard
    canvas.drawRect(Rect.fromLTWH(maxWidth - 6.0, 0, 1.5, barHeight), paint);
    canvas.drawRect(Rect.fromLTWH(maxWidth - 2.0, 0, 2.0, barHeight), paint);
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) => oldDelegate.text != text;
}
