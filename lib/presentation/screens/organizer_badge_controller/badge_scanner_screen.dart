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

  // The badge usually stays in front of the camera while the controller
  // reads the result: once the dialog closes, the same code must not be
  // scanned again straight away (it logged 2-3 scans per person). A
  // different badge scans immediately.
  // Same badge is ignored until it has left the camera's view for
  // _goneFor (keeping the phone on it never rescans), and never within
  // _minGap of the previous result closing.
  static const Duration _goneFor = Duration(seconds: 2);
  static const Duration _minGap = Duration(seconds: 3);
  String? _lastValue;
  DateTime? _lastFinishedAt;
  DateTime? _lastSeenAt;

  /// true when [value] is the badge just handled and it is still (or again
  /// too soon) in front of the camera.
  bool _isRepeatOfLastBadge(String value) {
    final finishedAt = _lastFinishedAt;
    if (value != _lastValue || finishedAt == null) return false;
    final now = DateTime.now();
    final lastSeen = _lastSeenAt ?? finishedAt;
    _lastSeenAt = now;
    return now.difference(lastSeen) < _goneFor ||
        now.difference(finishedAt) < _minGap;
  }

  void _finishProcessing() {
    _lastFinishedAt = DateTime.now();
    if (mounted) setState(() => _isProcessing = false);
  }

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

    if (_isRepeatOfLastBadge(value)) return;
    _lastValue = value;
    _lastSeenAt = null;

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

        AppLogger.d('✅ API RESPONSE RECEIVED - status: ${response['status']}');

        final participant =
            (response['participant'] as Map?)?.cast<String, dynamic>();
        final scanId = response['scan_id'];
        final status = response['status'];

        // success, or "not registered" (error with a participant): both are
        // logged scans, so show the person and let the controller record
        // "Laisser entrer" / "Refuser l'accès".
        if (status == 'success' || (status == 'error' && participant != null)) {
          final paidItems = response['paid_items'] as List? ?? [];
          final dialogData = {
            'full_name': participant?['name'],
            'email': participant?['email'],
            'badge_id': participant?['badge_id'],
            'paid_items': status == 'success' ? paidItems : <dynamic>[],
            'registered': status == 'success',
            'message': response['message'],
            'scan_id': scanId is int ? scanId : int.tryParse('${scanId ?? ''}'),
          };

          if (mounted) {
            // Keep the scanner locked for as long as the dialog is on
            // screen -- the camera never stops, so clearing the flag any
            // earlier lets the same still-in-frame badge retrigger a
            // second (stacked) scan before the controller can react.
            await ParticipantVerificationDialog.show(
              context,
              dialogData,
              onDecision: (decision) => _roomService.recordScanDecision(
                scanId: dialogData['scan_id'] as int,
                decision: decision,
              ),
            );
            _finishProcessing();
          }
        } else if (status == 'invalid') {
          await _showErrorDialog('QR code invalide',
              response['message'] ?? 'Ce QR code ne correspond à aucun badge.');
          _finishProcessing();
        } else {
          await _showErrorDialog('Erreur',
              response['message'] ?? 'Badge non reconnu pour cet événement.');
          _finishProcessing();
        }
      } catch (e) {
        AppLogger.d('❌ API CALL FAILED: $e');
        await _showErrorDialog('Erreur',
            'Impossible de vérifier le badge. Vérifiez la connexion et réessayez.');
        _finishProcessing();
      }
    } catch (e) {
      AppLogger.d('❌ EXCEPTION IN _verifyAccess: $e');
      await _showErrorDialog('Erreur', 'Erreur inattendue: $e');
      _finishProcessing();
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
            // Instructions above the frame: at a fixed distance from the
            // bottom they covered the frame's lower corners on tall phones.
            Positioned(
              top: 16,
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
