import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/room_service.dart';
import '../../../routes/app_router.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';
import 'participant_verification_result_screen.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class BadgeScannerScreen extends StatefulWidget {
  const BadgeScannerScreen({super.key});

  @override
  State<BadgeScannerScreen> createState() => _BadgeScannerScreenState();
}

class _BadgeScannerScreenState extends State<BadgeScannerScreen> {
  bool _isProcessing = false;
  final RoomService _roomService = RoomService(ApiClient());

  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/organizer-badge-controller/home':
        return 0;
      case '/organizer-badge-controller/announcements':
        return 1;
      case '/organizer-badge-controller/badge-scanner':
        return 2;
      case '/organizer-badge-controller/program':
        return 3;
      case '/organizer-badge-controller/stats':
        return 4;
      default:
        return 2;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;

    if (value == null || value.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    _verifyAccess(value);
  }

  Future<void> _verifyAccess(String qrData) async {
    try {
      AppLogger.d('═══════════════════════════════════════════════════════');
      AppLogger.d('🔍 RAW QR CODE DATA:');
      AppLogger.d(qrData);
      AppLogger.d('═══════════════════════════════════════════════════════');

      // The scanned value is just the user id as plain text -- passed
      // straight through to the API below, which does its own validation
      // and returns a proper 'invalid' status if it's malformed. No local
      // parsing needed (and none possible: a bare id isn't JSON).

      // NEW SIMPLIFIED APPROACH: No room selection needed
      // Controllers can scan badges anywhere and see ALL paid items

      try {
        final response = await _roomService.scanParticipant(
          qrData: qrData,
        );

        AppLogger.d('✅ API RESPONSE RECEIVED');
        AppLogger.d('   - status: ${response['status']}');

        if (response['status'] == 'success') {
          // Map API response to dialog format
          final participant = response['participant'] as Map<String, dynamic>;
          final event = response['event'] as Map<String, dynamic>?;
          final paidItems = response['paid_items'] as List? ?? [];

          AppLogger.d('💰 PAID ITEMS FROM DATABASE: ${paidItems.length}');
          AppLogger.d('💵 TOTAL AMOUNT: ${response['total_amount']}');
          if (event != null) {
            AppLogger.d('🎉 EVENT: ${event['name']}');
          }

          // Create data structure for dialog
          final dialogData = {
            'full_name': participant['name'],
            'email': participant['email'],
            'badge_id': participant['badge_id'],
            'paid_items': paidItems,
            'total_paid_items':
                response['total_paid_items'] ?? paidItems.length,
            'total_amount': response['total_amount'] ?? 0.0,
            'event_name': event?['name'],
          };

          if (mounted) {
            // Keep the scanner locked for as long as the dialog is on
            // screen -- the camera never stops, so clearing the flag any
            // earlier lets the same still-in-frame badge retrigger a
            // second (stacked) scan before the controller can react.
            await ParticipantVerificationDialog.show(context, dialogData);
            if (mounted) setState(() => _isProcessing = false);
          }
        } else if (response['status'] == 'error') {
          await _showErrorDialog(
              'Erreur',
              response['message'] ??
                  'Participant non enregistré pour cet événement');
          if (mounted) setState(() => _isProcessing = false);
        } else {
          await _showErrorDialog('Erreur', 'QR code invalide');
          if (mounted) setState(() => _isProcessing = false);
        }
      } catch (e) {
        AppLogger.d('❌ API CALL FAILED: $e');
        await _showErrorDialog('Erreur', 'Impossible de vérifier l\'accès: $e');
        if (mounted) setState(() => _isProcessing = false);
      }
    } catch (e) {
      AppLogger.d('❌ EXCEPTION IN _verifyAccess: $e');
      await _showErrorDialog('Erreur', 'Erreur inattendue: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showErrorDialog(String title, String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RootTabPopScope(
      homeRoute: AppRouter.organizerBadgeControllerHome,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(
                  context, AppRouter.organizerBadgeControllerHome);
            },
          ),
          title: const Text(
            'Scanner un badge',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Stack(
          children: [
            MobileScanner(
              onDetect: _onDetect,
            ),
            // Custom overlay
            CustomPaint(
              painter: _ScannerOverlay(color: AppColors.eventPrimary(context)),
              child: Container(),
            ),
            // Instructions
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Placez le QR code du badge dans le cadre',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _getCurrentIndex(context),
          userRole: 'organizer_badge_controller',
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(
                    context, AppRouter.organizerBadgeControllerHome);
                break;
              case 1:
                Navigator.pushReplacementNamed(
                  context,
                  AppRouter.badgeControllerAnnouncements,
                );
                break;
              case 2:
                break;
              case 3:
                Navigator.pushReplacementNamed(
                    context, AppRouter.badgeControllerProgram);
                break;
              case 4:
                Navigator.pushReplacementNamed(
                    context, AppRouter.badgeControllerStats);
                break;
            }
          },
        ),
      ),
    );
  }
}

class _ScannerOverlay extends CustomPainter {
  final Color color;

  _ScannerOverlay({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    // Semi-transparent overlay
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    canvas.drawRect(Rect.fromLTWH(0, top, left, scanAreaSize), paint);
    canvas.drawRect(
        Rect.fromLTWH(left + scanAreaSize, top, left, scanAreaSize), paint);
    canvas.drawRect(
        Rect.fromLTWH(0, top + scanAreaSize, size.width,
            size.height - top - scanAreaSize),
        paint);

    // Corner borders
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
        Offset(left, top), Offset(left + cornerLength, top), borderPaint);
    canvas.drawLine(
        Offset(left, top), Offset(left, top + cornerLength), borderPaint);

    // Top-right
    canvas.drawLine(Offset(left + scanAreaSize - cornerLength, top),
        Offset(left + scanAreaSize, top), borderPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top),
        Offset(left + scanAreaSize, top + cornerLength), borderPaint);

    // Bottom-left
    canvas.drawLine(Offset(left, top + scanAreaSize - cornerLength),
        Offset(left, top + scanAreaSize), borderPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize),
        Offset(left + cornerLength, top + scanAreaSize), borderPaint);

    // Bottom-right
    canvas.drawLine(
        Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
        Offset(left + scanAreaSize, top + scanAreaSize),
        borderPaint);
    canvas.drawLine(
        Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
        Offset(left + scanAreaSize, top + scanAreaSize),
        borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
