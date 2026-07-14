// lib/presentation/screens/exposant/exposant_scanner_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
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
  late ExposantScanService _exposantScanService;
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _exposantScanService = ExposantScanService(_apiClient);
  }

  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/exposant/home':
        return 0;
      case '/exposant/guide':
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
      // Parse QR code to get participant info
      final qrData = jsonDecode(code);
      final participantName = qrData['full_name'] ??
          '${qrData['first_name'] ?? ''} ${qrData['last_name'] ?? ''}'.trim();
      final participantEmail = qrData['email'] ?? '';

      if (!mounted) return;

      // Show dialog to get remarque before saving
      await _showScanConfirmationDialog(
        qrCode: code,
        participantName: participantName,
        participantEmail: participantEmail,
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de lecture du QR code: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Show dialog to confirm scan and add remarque
  Future<void> _showScanConfirmationDialog({
    required String qrCode,
    required String participantName,
    required String participantEmail,
  }) async {
    final TextEditingController remarqueController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Only close via buttons
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Enregistrer la visite',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Participant info (without background)
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        participantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (participantEmail.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email,
                          size: 16,
                          color: AppColors.textSecondary(dialogContext)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          participantEmail,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary(dialogContext),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                // Remarque field
                const Text(
                  'Remarque (optionnel):',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: remarqueController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Intéressé par...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),
            // Save button
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    // Get remarque text before disposing (if user clicked save)
    final remarque = result == true ? remarqueController.text.trim() : '';

    // Check if widget is still mounted before setState
    if (!mounted) {
      remarqueController.dispose();
      return;
    }

    // Resume scanning first (before disposing controller)
    setState(() {
      _isProcessing = false;
    });

    // Dispose controller AFTER setState completes
    // Use addPostFrameCallback to ensure disposal happens after rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      remarqueController.dispose();
    });

    // Handle dialog result
    if (result == true) {
      // User clicked save - proceed with scan
      await _saveScan(
        qrCode: qrCode,
        remarque: remarque,
      );
    }
  }

  /// Save scan to backend
  Future<void> _saveScan({
    required String qrCode,
    required String remarque,
  }) async {
    try {
      // Get auth state to get event ID
      final authState = context.read<AuthBloc>().state;

      if (authState.status == AuthStatus.authenticated &&
          authState.event != null) {
        // Call API to save scan
        final scanResult = await _exposantScanService.scanParticipant(
          qrData: qrCode,
          eventId: authState.event!.id,
          notes: remarque.isEmpty ? null : remarque,
        );

        if (!mounted) return;

        debugPrint('✅ Scan recorded successfully');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Visite enregistrée: ${scanResult.participantName ?? "Participant"}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Événement non sélectionné'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('❌ Failed to record scan: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
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
      ..color = Colors.black.withValues(alpha: 0.5)
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
