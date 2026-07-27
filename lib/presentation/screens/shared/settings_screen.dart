// lib/presentation/screens/shared/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_event.dart';
import '../../../routes/app_router.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return RootTabPopScope(
      // Only the room-manager role reaches this screen via the bottom nav
      // (as its "Paramètres" tab, pushReplacementNamed — stack root, nothing
      // to pop to). Every other role pushes this normally from a gear icon,
      // where canPop() is already true and this homeRoute never applies.
      homeRoute: AppRouter.organizerRoomManagerHome,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres'),
        ),
        body: ListView(
          children: [
            const SizedBox(height: 10),

            // Account Section
            _buildSectionHeader(context, 'Compte'),
            _buildSettingsTile(
              context,
              icon: Icons.person_outline,
              title: 'Profil',
              subtitle: 'Gérer vos informations personnelles',
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.profileSettings),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.lock_outline,
              title: 'Sécurité',
              subtitle: 'Mot de passe et authentification',
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.securitySettings),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.delete_outline,
              title: 'Supprimer mon compte',
              subtitle: 'Suppression définitive de votre compte',
              textColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () => _showDeleteAccountDialog(context),
            ),

            const SizedBox(height: 20),

            // Support Section
            _buildSectionHeader(context, 'Support'),
            _buildSettingsTile(
              context,
              icon: Icons.help_outline,
              title: 'Aide',
              subtitle: 'FAQ et support',
              onTap: () => Navigator.pushNamed(context, AppRouter.helpSettings),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.info_outline,
              title: 'À propos',
              subtitle: 'Version et informations',
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.aboutSettings),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Confidentialité',
              subtitle: 'Politique de confidentialité',
              onTap: () =>
                  Navigator.pushNamed(context, AppRouter.privacySettings),
            ),

            const SizedBox(height: 20),

            // Logout Section
            _buildSectionHeader(context, 'Session'),
            _buildSettingsTile(
              context,
              icon: Icons.logout,
              title: 'Déconnexion',
              subtitle: 'Se déconnecter de l\'application',
              textColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () => _showLogoutDialog(context),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ), // End Scaffold
    ); // End RootTabPopScope
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.eventPrimary(context))
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.eventPrimary(context),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor ?? AppColors.textPrimary(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary(context),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textHint(context),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.login,
                (route) => false,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool isDeleting = false;
    String? errorText;

    // Dialog-scoped controller with no State object of its own to hook
    // dispose() into, so it's cleaned up explicitly once the route closes.
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: !isDeleting,
              child: AlertDialog(
                title: const Text('Supprimer mon compte'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cette action est définitive : votre compte sera '
                      'désactivé et vos informations personnelles '
                      'anonymisées. Vous ne pourrez plus vous reconnecter.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        errorText: errorText,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed:
                        isDeleting ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: isDeleting
                        ? null
                        : () async {
                            final password = passwordController.text;
                            if (password.isEmpty) {
                              setDialogState(() {
                                errorText = 'Mot de passe requis';
                              });
                              return;
                            }

                            setDialogState(() {
                              isDeleting = true;
                              errorText = null;
                            });

                            try {
                              await context
                                  .read<AuthRepository>()
                                  .deleteAccount(password: password);

                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext);

                              if (!context.mounted) return;
                              context
                                  .read<AuthBloc>()
                                  .add(const AuthLogoutRequested());

                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (confirmContext) => AlertDialog(
                                  title: const Text('Compte supprimé'),
                                  content: const Text(
                                    'Votre compte a bien été supprimé.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(confirmContext),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );

                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRouter.login,
                                (route) => false,
                              );
                            } catch (e) {
                              if (!dialogContext.mounted) return;
                              setDialogState(() {
                                isDeleting = false;
                                errorText = e
                                    .toString()
                                    .replaceFirst('Exception: ', '');
                              });
                            }
                          },
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Supprimer définitivement'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => passwordController.dispose());
  }
}
