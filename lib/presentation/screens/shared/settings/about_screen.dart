// lib/presentation/screens/shared/settings/about_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
        title: const Text('À propos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.eventPrimary(context).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/logos/Les adidas.svg',
                width: 64,
                height: 64,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Make',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: 'Plus',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Events Management',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.info_outline,
                label: 'Version',
                value: '1.0.0 (build 1)',
              ),
              _InfoRow(
                icon: Icons.description_outlined,
                label: 'Description',
                value: 'Application mobile officielle de gestion '
                    'd\'événements DendrIQ : programme, badges, '
                    'sessions et annonces en temps réel.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            children: [
              InkWell(
                onTap: _emailSupport,
                borderRadius: BorderRadius.circular(12),
                child: _InfoRow(
                  icon: Icons.mail_outline,
                  label: 'Contact',
                  value: 'support@makeplus.com',
                  valueColor: AppColors.eventPrimary(context),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: AppColors.textHint(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              '© 2026 DendrIQ. Tous droits réservés.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint(context),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Développé avec ❤️ en Algérie',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: AppColors.borderColor(context)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.eventPrimary(context)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
