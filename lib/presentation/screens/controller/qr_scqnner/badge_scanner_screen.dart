// lib/presentation/screens/controller/qr_scanner/badge_scanner_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/theme/app_colors.dart';
import '../../../widgets/qr/qr_scanner_widget.dart';

class BadgeScannerScreen extends StatefulWidget {
  const BadgeScannerScreen({super.key});

  @override
  State<BadgeScannerScreen> createState() => _BadgeScannerScreenState();
}

class _BadgeScannerScreenState extends State<BadgeScannerScreen> {
  void _handleScan(String qrCode) {
    // Navigate to verification screen with scanned data
    Navigator.pushNamed(
      context,
      '/controller/participant-verified',
      arguments: qrCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRScannerWidget(
        onScan: _handleScan,
        title: 'Scanner QR',
        subtitle: 'Scannez le badge du participant',
      ),
    );
  }
}

// ========== Participant Verified Screen ==========

class ParticipantVerifiedScreen extends StatelessWidget {
  final String qrData;

  const ParticipantVerifiedScreen({
    super.key,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch participant data from API using qrData
    // For now, using mock data
    final participant = {
      'name': 'Amina BENDJEBBAR',
      'role': 'Participant - Conférencier',
      'room': 'Salle 3',
      'status': 'accepted', // or 'rejected'
    };

    final isAccepted = participant['status'] == 'accepted';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isAccepted
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isAccepted
                          ? AppColors.success
                          : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAccepted ? Icons.check : Icons.close,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Status Text
                  Text(
                    isAccepted ? 'Accepté' : 'Refusé',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isAccepted
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Participant Card
                  _buildParticipantCard(participant, isAccepted),

                  const SizedBox(height: 32),

                  // Room Info (if accepted)
                  if (isAccepted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.meeting_room,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            participant['room'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Reason (if rejected)
                  if (!isAccepted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Raison:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Badge invalide ou expiré',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Save verification log
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAccepted
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      child: const Text('Valider l\'entrée'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary Button
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Scanner un autre badge'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant, bool isAccepted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // QR Code Display
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.qr_code_2,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Participant Name
          Text(
            participant['name'] as String,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Participant Role
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isAccepted
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              participant['role'] as String,
              style: TextStyle(
                fontSize: 14,
                color: isAccepted ? AppColors.primary : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}