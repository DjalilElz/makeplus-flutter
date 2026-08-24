// lib/presentation/screens/shared/settings/terms_of_service_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/constants/theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const _sections = [
    (
      icon: Icons.check_circle_outline,
      title: 'Acceptation des conditions',
      body: 'En créant un compte ou en utilisant l\'application DendrIQ, '
          'vous acceptez les présentes conditions d\'utilisation. Si vous '
          'n\'êtes pas d\'accord, veuillez ne pas utiliser l\'application.',
    ),
    (
      icon: Icons.apps_outlined,
      title: 'Description du service',
      body: 'DendrIQ est une application de gestion d\'événements : '
          'programme des sessions, badge et code QR de participant, '
          'annonces, questions aux intervenants et soumissions '
          'scientifiques (e-posters). Certaines fonctionnalités varient '
          'selon votre rôle (participant, intervenant, organisateur...).',
    ),
    (
      icon: Icons.badge_outlined,
      title: 'Votre compte',
      body: 'Vous êtes responsable de l\'exactitude des informations '
          'fournies lors de l\'inscription et de la confidentialité de '
          'votre mot de passe. Votre compte est personnel : le badge et '
          'le code QR associés ne doivent pas être partagés ni utilisés '
          'par une autre personne.',
    ),
    (
      icon: Icons.gavel_outlined,
      title: 'Utilisation acceptable',
      body: 'Vous vous engagez à ne pas : usurper l\'identité d\'une autre '
          'personne, falsifier ou partager frauduleusement un badge, '
          'perturber le fonctionnement de l\'application, ou soumettre du '
          'contenu (questions, e-posters) illégal, injurieux ou trompeur.',
    ),
    (
      icon: Icons.forum_outlined,
      title: 'Contenu que vous soumettez',
      body: 'Les questions posées aux intervenants et les contributions '
          'scientifiques (e-posters) que vous soumettez restent votre '
          'propriété. En les soumettant, vous autorisez les organisateurs '
          'de l\'événement concerné à les afficher et les utiliser dans le '
          'cadre de cet événement.',
    ),
    (
      icon: Icons.event_outlined,
      title: 'Rôle des organisateurs',
      body: 'DendrIQ fournit la plateforme technique. Le contenu de '
          'chaque événement (programme, salles, annonces, décisions '
          'd\'accès) est géré par les organisateurs de cet événement, qui '
          'en sont responsables.',
    ),
    (
      icon: Icons.copyright_outlined,
      title: 'Propriété intellectuelle',
      body: 'Le nom DendrIQ, son logo et l\'application elle-même sont '
          'la propriété de DendrIQ. Vous ne pouvez pas les reproduire ou '
          'les utiliser en dehors de l\'usage prévu par l\'application '
          'sans autorisation.',
    ),
    (
      icon: Icons.block_outlined,
      title: 'Suspension et résiliation',
      body: 'Votre accès peut être suspendu ou votre compte supprimé en '
          'cas de non-respect de ces conditions. Vous pouvez à tout '
          'moment supprimer votre compte depuis Paramètres > Compte > '
          'Supprimer mon compte.',
    ),
    (
      icon: Icons.warning_amber_outlined,
      title: 'Limitation de responsabilité',
      body: 'L\'application est fournie "en l\'état". DendrIQ met tout '
          'en œuvre pour assurer son bon fonctionnement mais ne peut '
          'garantir une disponibilité ininterrompue et n\'est pas '
          'responsable des décisions prises par les organisateurs d\'un '
          'événement.',
    ),
    (
      icon: Icons.update_outlined,
      title: 'Modifications',
      body: 'Ces conditions peuvent être mises à jour ; la version en '
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
        title: const Text('Conditions d\'utilisation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Conditions d\'utilisation',
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
          const SizedBox(height: 20),
          for (final section in _sections) ...[
            _TermsSection(
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
                    'Pour toute question concernant ces conditions, '
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

class _TermsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _TermsSection({
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
