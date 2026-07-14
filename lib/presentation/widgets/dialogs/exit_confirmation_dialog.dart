// lib/presentation/widgets/dialogs/exit_confirmation_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/theme/app_colors.dart';

/// Show exit confirmation dialog
/// Returns true if user wants to exit, false otherwise
Future<bool> showExitConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text(
          'Quitter l\'application',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir quitter l\'application?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Annuler'),
          ),
          // Exit button
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitter'),
          ),
        ],
      );
    },
  );

  // If user confirmed exit, close the app
  if (result == true) {
    SystemNavigator.pop();
    return true;
  }

  return false;
}
