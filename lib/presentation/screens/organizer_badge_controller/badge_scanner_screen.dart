// lib/presentation/screens/organizer_badge_controller/badge_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../routes/app_router.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class BadgeScannerScreen extends StatefulWidget {
  const BadgeScannerScreen({super.key});

  @override
  State<BadgeScannerScreen> createState() => _BadgeScannerScreenState();
}

class _BadgeScannerScreenState extends State<BadgeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  late ApiClient _apiClient;
  String? _currentRoomId;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _loadCurrentRoom();
  }

  Future<void> _loadCurrentRoom() async {
    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id;

      if (userId == null) return;

      // Get user's current room assignment
      final response = await _apiClient.get(
        '/room-assignments/',
        queryParameters: {
          'user_id': userId.toString(),
          'current': 'true',
        },
      );

      final assignments = response.data['results'] as List?;
      if (assignments != null && assignments.isNotEmpty) {
        setState(() {
          _currentRoomId = assignments.first['room'] as String?;
        });
      }
    } catch (e) {
      print('❌ ERROR LOADING ROOM: $e');
    }
  }

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

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Verify access via API
    _verifyAccess(code);
  }

  Future<void> _verifyAccess(String qrData) async {
    if (_currentRoomId == null) {
      _showErrorDialog('Aucune salle assignée',
          'Impossible de vérifier l\'accès sans salle assignée.');
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final response = await _apiClient.post(
        '/rooms/$_currentRoomId/verify_access/',
        data: {'qr_data': qrData},
      );

      final data = response.data;
      final status = data['status'];

      if (status == 'granted') {
        _showAccessGrantedDialog(data);
      } else {
        _showAccessDeniedDialog(data);
      }
    } catch (e) {
      print('❌ ERROR VERIFYING ACCESS: $e');
      _showErrorDialog('Erreur', 'Impossible de vérifier l\'accès: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _showAccessGrantedDialog(Map<String, dynamic> data) {
    final participant = data['participant'] as Map<String, dynamic>?;
    final access = data['access'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Accès autorisé',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (participant != null) ...[
                _buildInfoRow('Nom', participant['name'] ?? 'N/A'),
                _buildInfoRow('Email', participant['email'] ?? 'N/A'),
                _buildInfoRow('Badge', participant['badge_id'] ?? 'N/A'),
              ],
              if (access != null) ...[
                _buildInfoRow('Salle', access['room_name'] ?? 'N/A'),
                _buildInfoRow('Statut', 'Accès accordé',
                    color: AppColors.success),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isProcessing = false;
                });
              },
              child: const Text('Scanner un autre'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(
                    context, AppRouter.organizerBadgeControllerHome);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        );
      },
    );
  }

  void _showAccessDeniedDialog(Map<String, dynamic> data) {
    final message = data['message'] ?? 'Accès refusé';
    final participant = data['participant'] as Map<String, dynamic>?;
    final user = data['user'] as Map<String, dynamic>?;
    final session = data['session'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Accès refusé',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              if (participant != null) ...[
                _buildInfoRow('Nom', participant['name'] ?? 'N/A'),
                _buildInfoRow('Badge', participant['badge_id'] ?? 'N/A'),
              ] else if (user != null) ...[
                _buildInfoRow('Nom', user['name'] ?? 'N/A'),
                _buildInfoRow('Email', user['email'] ?? 'N/A'),
              ],
              if (session != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Session:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildInfoRow('Titre', session['title'] ?? 'N/A'),
                _buildInfoRow('Prix', '${session['price']} DA',
                    color: AppColors.error),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isProcessing = false;
                });
              },
              child: const Text('Scanner un autre'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(
                    context, AppRouter.organizerBadgeControllerHome);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
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
                setState(() => _isProcessing = false);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
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
              // Already on scanner
              break;
            case 3:
              Navigator.pushReplacementNamed(
                  context, AppRouter.badgeControllerProgram);
              break;
            case 4:
              // Questions
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
