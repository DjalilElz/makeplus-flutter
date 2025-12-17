// lib/presentation/screens/exposant/exposant_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/qr_service.dart';
import '../../../data/services/exposant_scan_service.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class ExposantScannerScreen extends StatefulWidget {
  const ExposantScannerScreen({super.key});

  @override
  State<ExposantScannerScreen> createState() => _ExposantScannerScreenState();
}

class _ExposantScannerScreenState extends State<ExposantScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  late QRService _qrService;
  late ExposantScanService _exposantScanService;
  late ApiClient _apiClient;
  String? _exposantParticipantId; // Store exposant's participant UUID

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _qrService = QRService(_apiClient);
    _exposantScanService = ExposantScanService(_apiClient);
    _loadExposantParticipantId();
  }

  /// Fetch exposant's participant UUID from backend
  /// This is needed because backend requires participant UUID, not user ID
  Future<void> _loadExposantParticipantId() async {
    try {
      // Try to get from /auth/profile/
      final response = await _apiClient.get('/auth/profile/');
      final profileData = response.data;

      // Check various possible fields for participant ID
      if (profileData['participant_id'] != null) {
        _exposantParticipantId = profileData['participant_id'].toString();
      } else if (profileData['participant'] != null) {
        if (profileData['participant'] is Map) {
          _exposantParticipantId = profileData['participant']['id']?.toString();
        } else {
          _exposantParticipantId = profileData['participant'].toString();
        }
      }

      if (_exposantParticipantId != null) {
        debugPrint('✅ Exposant Participant ID loaded: $_exposantParticipantId');
      } else {
        debugPrint('⚠️ Could not find exposant participant ID in profile');
      }
    } catch (e) {
      debugPrint('❌ Error loading exposant participant ID: $e');
    }
  }

  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/exposant/home':
        return 0;
      case '/exposant/plan':
        return 1;
      case '/exposant/scanner':
        return 2;
      case '/exposant/stats':
        return 3;
      case '/exposant/announcements':
        return 4;
      default:
        return 2;
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Verify QR code with backend
      final result = await _qrService.verifyQRCode(qrData: code);

      if (!mounted) return;

      if (result.valid && result.participant != null) {
        // Get auth state to get event ID
        final authState = context.read<AuthBloc>().state;

        if (authState.status == AuthStatus.authenticated) {
          // Record the scan using exposant's participant UUID
          try {
            // Use stored participant UUID or fallback to user ID as string
            final exposantId =
                _exposantParticipantId ?? authState.user?.id.toString() ?? '';

            if (_exposantParticipantId == null) {
              debugPrint(
                  '⚠️ Using user ID as fallback. Backend may require participant UUID.');
            }

            await _exposantScanService.scanParticipant(
              exposantId: exposantId,
              scannedParticipantId: result.participant!.id,
              eventId: authState.event?.id ?? '',
              notes: null,
            );

            debugPrint('✅ Scan recorded successfully');
          } catch (e) {
            // Scan recording failed but still show participant info
            debugPrint('❌ Failed to record scan: $e');

            // Show error to user if scan recording fails
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur d\'enregistrement: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        } // Navigate to participant info screen with real data
        Navigator.pushNamed(
          context,
          '/exposant/participant-info',
          arguments: result.participant,
        ).then((_) {
          setState(() {
            _isProcessing = false;
          });
        });
      } else {
        // Invalid QR code
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'QR code invalide'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de vérification: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scanner un badge',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () {
              cameraController.switchCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: cameraController,
            onDetect: _onBarcodeDetect,
          ),

          // Overlay with scanning area
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),

          // Instructions at bottom
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
                      color: Colors.black.withOpacity(0.7),
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
        userRole: 'exposant',
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/exposant/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/exposant/plan');
              break;
            case 2:
              // Already on scanner
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/exposant/stats');
              break;
            case 4:
              Navigator.pushReplacementNamed(
                  context, '/exposant/announcements');
              break;
          }
        },
      ),
    );
  }
}

// Custom painter for scanner overlay
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    // Draw semi-transparent overlay
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Top
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    // Left
    canvas.drawRect(Rect.fromLTWH(0, top, left, scanAreaSize), paint);
    // Right
    canvas.drawRect(
        Rect.fromLTWH(left + scanAreaSize, top, left, scanAreaSize), paint);
    // Bottom
    canvas.drawRect(
        Rect.fromLTWH(0, top + scanAreaSize, size.width,
            size.height - top - scanAreaSize),
        paint);

    // Draw corner borders
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
        Offset(left, top), Offset(left + cornerLength, top), borderPaint);
    canvas.drawLine(
        Offset(left, top), Offset(left, top + cornerLength), borderPaint);

    // Top-right corner
    canvas.drawLine(Offset(left + scanAreaSize - cornerLength, top),
        Offset(left + scanAreaSize, top), borderPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top),
        Offset(left + scanAreaSize, top + cornerLength), borderPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, top + scanAreaSize - cornerLength),
        Offset(left, top + scanAreaSize), borderPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize),
        Offset(left + cornerLength, top + scanAreaSize), borderPaint);

    // Bottom-right corner
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
