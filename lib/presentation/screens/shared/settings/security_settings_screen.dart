// lib/presentation/screens/shared/settings/security_settings_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/theme/app_colors.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sécurité'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: AppColors.eventPrimary(context),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Changer le mot de passe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Pour des raisons de sécurité, le changement de mot de '
                  'passe n\'est pas disponible directement dans '
                  'l\'application mobile.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Veuillez contacter les organisateurs de votre événement '
                  'pour effectuer cette opération.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary(context),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
