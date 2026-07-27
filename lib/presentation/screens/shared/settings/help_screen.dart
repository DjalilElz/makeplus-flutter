// lib/presentation/screens/shared/settings/help_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/theme/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      question: 'Comment accéder aux sessions ?',
      answer: 'Ouvrez l\'onglet "Programme" en bas de l\'écran. Vous y '
          'retrouvez toutes les sessions de l\'événement, avec des filtres '
          'par type, statut, salle et date. Touchez une session pour voir '
          'ses détails, suivre le direct si disponible, ou poser une '
          'question à l\'intervenant.',
    ),
    (
      question: 'Comment fonctionne le badge et le code QR ?',
      answer: 'Votre badge et son code QR sont générés automatiquement dès '
          'votre inscription et accessibles depuis votre profil. '
          'Présentez-le aux contrôleurs à l\'entrée des salles et sessions '
          'pour vérifier votre accès.',
    ),
    (
      question: 'Comment modifier mes informations ?',
      answer: 'Rendez-vous dans Paramètres > Profil pour mettre à jour '
          'votre prénom et votre nom. L\'adresse email n\'est pas '
          'modifiable directement dans l\'application.',
    ),
    (
      question: 'Comment supprimer mon compte ?',
      answer: 'Rendez-vous dans Paramètres > Compte > Supprimer mon '
          'compte. Cette action est définitive et nécessite de saisir '
          'votre mot de passe.',
    ),
    (
      question: 'Comment contacter le support ?',
      answer: 'Écrivez-nous à support@makeplus.com, ou contactez '
          'directement les organisateurs de votre événement pour toute '
          'question spécifique (mot de passe, inscription, badge).',
    ),
  ];

  Future<void> _emailSupport() async {
    final uri = Uri(scheme: 'mailto', path: 'support@makeplus.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Aide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Questions fréquentes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          for (final faq in _faqs) ...[
            _FaqTile(question: faq.question, answer: faq.answer),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.eventPrimary(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: _emailSupport,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.mail_outline,
                      color: AppColors.eventPrimary(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Besoin d\'aide supplémentaire ?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'support@makeplus.com',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.eventPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.eventPrimary(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    widget.answer,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
                secondChild: const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
