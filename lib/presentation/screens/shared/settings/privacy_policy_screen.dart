// lib/presentation/screens/shared/settings/privacy_policy_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/constants/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      icon: Icons.badge_outlined,
      title: 'Données de compte',
      body: 'Lors de l\'inscription et de la connexion, nous traitons '
          'votre prénom, nom et adresse email, ainsi qu\'un mot de passe '
          'stocké de façon sécurisée (chiffré, jamais en clair). Ces '
          'informations servent à créer votre compte et à vous '
          'authentifier.',
    ),
    (
      icon: Icons.event_note_outlined,
      title: 'Données d\'événement et d\'inscription',
      body: 'Votre compte est associé aux événements auxquels vous '
          'participez : sessions suivies, salle assignée, badge et code '
          'QR de participant. Ces données sont gérées par les '
          'organisateurs de l\'événement concerné et utilisées pour le '
          'contrôle d\'accès et la gestion de votre participation.',
    ),
    (
      icon: Icons.qr_code_scanner_outlined,
      title: 'Caméra',
      body: 'L\'application demande l\'accès à la caméra uniquement pour '
          'scanner les codes QR des badges (contrôle d\'accès aux salles '
          'et sessions). Le flux vidéo est traité localement sur votre '
          'appareil pour décoder le code QR : il n\'est ni enregistré, ni '
          'transmis, ni stocké.',
    ),
    (
      icon: Icons.phonelink_lock_outlined,
      title: 'Données techniques et stockage local',
      body: 'Un jeton d\'authentification (JWT) est stocké de façon '
          'sécurisée sur votre appareil pour garder votre session active. '
          'Certaines préférences non sensibles (dernier événement '
          'consulté, etc.) sont conservées localement sur l\'appareil.',
    ),
    (
      icon: Icons.block_outlined,
      title: 'Ce que nous ne faisons pas',
      body: 'DendrIQ n\'utilise aucun outil d\'analyse ou de suivi '
          'publicitaire, ne partage aucune donnée à des fins commerciales '
          'ou publicitaires, et ne collecte pas votre position '
          'géographique.',
    ),
    (
      icon: Icons.groups_outlined,
      title: 'Partage des données',
      body: 'Vos données sont accessibles aux organisateurs de '
          'l\'événement auquel vous êtes inscrit (dans la mesure '
          'nécessaire à la gestion de l\'événement) et ne sont partagées '
          'avec aucun tiers en dehors de ce cadre.',
    ),
    (
      icon: Icons.verified_user_outlined,
      title: 'Vos droits',
      body: 'Vous pouvez consulter et modifier votre prénom et votre nom '
          'depuis Paramètres > Profil. Depuis Paramètres > Compte > '
          '"Supprimer mes données pour cet événement", vous pouvez '
          'supprimer votre inscription, vos accès et vos questions posées '
          'pour un événement particulier, sans supprimer votre compte ni '
          'vos autres événements. Vous pouvez aussi supprimer '
          'définitivement votre compte et les données associées depuis '
          'Paramètres > Compte > Supprimer mon compte.',
    ),
    (
      icon: Icons.child_care_outlined,
      title: 'Données des mineurs',
      body: 'DendrIQ n\'est pas destiné aux enfants et ne collecte pas '
          'sciemment de données concernant des mineurs.',
    ),
    (
      icon: Icons.update_outlined,
      title: 'Modifications',
      body: 'Cette politique peut être mise à jour ; la version en '
          'vigueur est toujours consultable ici, dans l\'application.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Confidentialité'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Politique de confidentialité',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dernière mise à jour : 2026',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'DendrIQ respecte votre vie privée. Cette page explique '
            'quelles données l\'application mobile collecte, pourquoi, et '
            'comment les gérer.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 20),
          for (final section in _sections) ...[
            _PolicySection(
              icon: section.icon,
              title: section.title,
              body: section.body,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.eventPrimary(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mail_outline,
                  color: AppColors.eventPrimary(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Pour toute question concernant vos données, '
                    'contactez-nous à support@makeplus.com.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textPrimary(context),
                    ),
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

class _PolicySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PolicySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.eventPrimary(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
