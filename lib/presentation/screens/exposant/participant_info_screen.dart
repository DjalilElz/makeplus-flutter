// lib/presentation/screens/exposant/participant_info_screen.dart

import 'package:flutter/material.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/models/participant_model.dart';

class ParticipantInfoScreen extends StatelessWidget {
  final dynamic scannedData; // Can be String (old) or ParticipantModel (new)

  const ParticipantInfoScreen({
    super.key,
    required this.scannedData,
  });

  @override
  Widget build(BuildContext context) {
    // Handle both old string argument and new ParticipantModel
    final ParticipantModel? participant = scannedData is ParticipantModel
        ? scannedData as ParticipantModel
        : null;

    final String scannedCode = scannedData is String
        ? scannedData as String
        : participant?.badgeNumber ?? '';

    // Use real participant data if available, otherwise mock data
    final participantData = participant != null
        ? {
            'nom': participant.fullName,
            'prenom': participant.firstName ?? '',
            'email': participant.email ?? 'Non disponible',
            'telephone': '+213 555 123 456', // Not in model yet
            'organisation': 'Non disponible', // Not in model yet
            'type': 'Participant',
            'badge': participant.badgeNumber,
            'statut': 'Actif',
          }
        : {
            'nom': 'Amina BENDJEBBAR',
            'prenom': 'Amina',
            'email': 'amina.bendjebbar@email.com',
            'telephone': '+213 555 123 456',
            'organisation': 'Université d\'Alger',
            'type': 'Participant',
            'badge': scannedCode,
            'statut': 'Actif',
          };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Information du visiteur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Participant Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations du participant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    context,
                    'Nom complet',
                    participantData['nom']!,
                    Icons.person,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    'Email',
                    participantData['email']!,
                    Icons.email,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    'Téléphone',
                    participantData['telephone']!,
                    Icons.phone,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    'Organisation',
                    participantData['organisation']!,
                    Icons.business,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    'Type',
                    participantData['type']!,
                    Icons.badge,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    'Code badge',
                    participantData['badge']!,
                    Icons.qr_code,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    'Statut',
                    participantData['statut']!,
                    Icons.check_circle,
                    valueColor: AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Save participant scan to database
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Visiteur enregistré avec succès'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  // Navigate back to scanner or home
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Annuler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value,
      IconData icon, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
