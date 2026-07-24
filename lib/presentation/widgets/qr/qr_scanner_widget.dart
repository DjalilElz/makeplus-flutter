// lib/presentation/widgets/qr/qr_scanner_widget.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/theme/app_colors.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String) onScan;
  final String? title;
  final String? subtitle;

  const QRScannerWidget({
    super.key,
    required this.onScan,
    this.title,
    this.subtitle,
  });

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isProcessing && capture.barcodes.isNotEmpty) {
      final String? code = capture.barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          isProcessing = true;
        });

        // Call the callback
        widget.onScan(code);

        // Reset after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              isProcessing = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // QR Scanner View
        MobileScanner(
          controller: controller,
          onDetect: _onDetect,
        ),

        // Scanner Overlay
        CustomPaint(
          painter: ScannerOverlay(
            borderColor: AppColors.eventPrimary(context),
            borderRadius: 16,
            borderLength: 40,
            borderWidth: 8,
            cutOutSize: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Container(),
        ),

        // Top Gradient Overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Header
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (widget.title != null)
                Text(
                  widget.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.subtitle!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        // Bottom Controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Flash Toggle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    controller.toggleTorch();
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                ),
                child: const Text(
                  'Annuler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Processing Indicator
        if (isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Traitement...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Custom painter for scanner overlay
class ScannerOverlay extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  ScannerOverlay({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutOutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutOutSize,
      height: cutOutSize,
    );

    final cutOutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)));

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawPath(
      Path.combine(PathOperation.difference, backgroundPath, cutOutPath),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw corners
    final left = cutOutRect.left;
    final top = cutOutRect.top;
    final right = cutOutRect.right;
    final bottom = cutOutRect.bottom;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left + borderRadius, top)
        ..lineTo(left + borderLength, top)
        ..moveTo(left, top + borderRadius)
        ..lineTo(left, top + borderLength),
      borderPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - borderLength, top)
        ..lineTo(right - borderRadius, top)
        ..moveTo(right, top + borderRadius)
        ..lineTo(right, top + borderLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - borderLength)
        ..lineTo(left, bottom - borderRadius)
        ..moveTo(left + borderRadius, bottom)
        ..lineTo(left + borderLength, bottom),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right, bottom - borderLength)
        ..lineTo(right, bottom - borderRadius)
        ..moveTo(right - borderRadius, bottom)
        ..lineTo(right - borderLength, bottom),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Usage Screen Example
class QRScannerScreen extends StatelessWidget {
  final Function(String) onScan;
  final String? title;
  final String? subtitle;

  const QRScannerScreen({
    super.key,
    required this.onScan,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRScannerWidget(
        onScan: (code) {
          onScan(code);
          Navigator.of(context).pop(code);
        },
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}
