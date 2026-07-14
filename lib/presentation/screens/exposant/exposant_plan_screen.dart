// lib/presentation/screens/exposant/exposant_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

class ExposantPlanScreen extends StatefulWidget {
  const ExposantPlanScreen({super.key});

  @override
  State<ExposantPlanScreen> createState() => _ExposantPlanScreenState();
}

class _ExposantPlanScreenState extends State<ExposantPlanScreen> {
  Future<void> _openPdfUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ouverture du PDF...'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/exposant/home':
        return 0;
      case '/exposant/guide':
        return 1;
      case '/exposant/scanner':
        return 2;
      case '/exposant/stats':
        return 3;
      case '/exposant/announcements':
        return 4;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final event = (authState.status == AuthStatus.authenticated)
            ? authState.event
            : null;
        final guideUrl = event?.guideFile;
        final hasGuide = guideUrl != null && guideUrl.isNotEmpty;

        return RootTabPopScope(
          homeRoute: '/exposant/home',
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Guide'),
              actions: [
                if (hasGuide)
                  IconButton(
                    icon: const Icon(Icons.download, color: AppColors.primary),
                    onPressed: () => _downloadPdf(guideUrl),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF Container
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor(context)),
                    ),
                    child: Column(
                      children: [
                        // PDF Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Guide de l\'événement',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Document PDF • 2.1 MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // PDF Preview/Viewer Area
                        Expanded(
                          child: Center(
                            child: hasGuide
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.map,
                                        size: 80,
                                        color: AppColors.textHint(context),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Guide PDF disponible',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Le guide complet de l\'événement\navec toutes les informations pratiques',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () => _openPdfUrl(guideUrl),
                                        icon: const Icon(Icons.open_in_new),
                                        label: const Text('Ouvrir le PDF'),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 80,
                                        color: AppColors.textHint(context),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Guide non disponible',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Le guide de l\'événement\nn\'a pas encore été publié',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textHint(context),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Plan Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'À propos du guide',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(context, Icons.location_city, 'Lieu',
                            'Centre de Conférences'),
                        const SizedBox(height: 8),
                        _buildInfoRow(context, Icons.store,
                            'Stands d\'exposition', '50+ stands'),
                        const SizedBox(height: 8),
                        _buildInfoRow(context, Icons.restaurant,
                            'Espaces restauration', '3 zones disponibles'),
                        const SizedBox(height: 8),
                        _buildInfoRow(context, Icons.local_parking, 'Parking',
                            'Parking gratuit disponible'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // Extra space for bottom navbar
                ],
              ),
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: _getCurrentIndex(context),
              userRole: 'exposant',
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushReplacementNamed(context, '/exposant/home');
                    break;
                  case 1:
                    // Already on Guide
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/exposant/scanner');
                    break;
                  case 3:
                    Navigator.pushReplacementNamed(context, '/exposant/stats');
                    break;
                  case 4:
                    Navigator.pushReplacementNamed(
                        context, '/exposant/announcements');
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary(context),
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
