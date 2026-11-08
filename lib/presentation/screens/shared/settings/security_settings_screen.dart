// lib/presentation/screens/shared/settings/security_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/theme/app_colors.dart';
import '../../../../logic/authentication/auth_bloc.dart';
import '../../auth/forgot_password_screen.dart';

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
                  'Un code de confirmation sera envoyé à votre adresse e-mail '
                  'pour valider votre nouveau mot de passe.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.password),
                    label: const Text('Changer mon mot de passe'),
                    onPressed: () {
                      final email = context.read<AuthBloc>().state.user?.email;
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(
                          initialEmail: email,
                          changeMode: true,
                        ),
                      ));
                    },
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
