// lib/presentation/screens/organizer_badge_controller/program_pdf_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../../routes/app_router.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

class ProgramPdfScreen extends StatefulWidget {
  const ProgramPdfScreen({super.key});

  @override
  State<ProgramPdfScreen> createState() => _ProgramPdfScreenState();
}

class _ProgramPdfScreenState extends State<ProgramPdfScreen> {
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
          SnackBar(
            content: const Text('Ouverture du PDF...'),
            backgroundColor: AppColors.eventPrimary(context),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final event = (authState.status == AuthStatus.authenticated)
            ? authState.event
            : null;
        final programmeUrl = event?.programmeFile;
        final hasProgram = programmeUrl != null && programmeUrl.isNotEmpty;

        return RootTabPopScope(
          homeRoute: AppRouter.organizerBadgeControllerHome,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Programme'),
              actions: [
                if (hasProgram)
                  IconButton(
                    icon: Icon(Icons.download, color: AppColors.eventPrimary(context)),
                    onPressed: () => _downloadPdf(programmeUrl),
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
                            color: AppColors.eventPrimary(context).withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.eventPrimary(context),
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
                                      'Programme de l\'événement',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Document PDF • 2.5 MB',
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
                            child: hasProgram
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.description,
                                        size: 80,
                                        color: AppColors.textHint(context),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Programme PDF disponible',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Le programme complet de l\'événement\navec toutes les sessions et les horaires',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _openPdfUrl(programmeUrl),
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
                                        'Programme non disponible',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Le programme de l\'événement\nn\'a pas encore été publié',
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
                  // Program Info
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
                          'À propos du programme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                            context, Icons.event, 'Date', '15-17 Mars 2024'),
                        const SizedBox(height: 8),
                        _buildInfoRow(context, Icons.location_on, 'Lieu',
                            'Centre de Conférences'),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            context, Icons.schedule, 'Durée', '3 jours'),
                        const SizedBox(height: 8),
                        _buildInfoRow(context, Icons.groups, 'Sessions',
                            '24 sessions au total'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 3, // Programme tab
              userRole: 'organizer_badge_controller',
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushReplacementNamed(
                        context, AppRouter.organizerBadgeControllerHome);
                    break;
                  case 1:
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.badgeControllerAnnouncements,
                    );
                    break;
                  case 2:
                    Navigator.pushReplacementNamed(
                        context, AppRouter.badgeScanner);
                    break;
                  case 3:
                    // Already on program
                    break;
                  case 4:
                    Navigator.pushReplacementNamed(
                        context, AppRouter.badgeControllerStats);
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
      children: [
        Icon(icon, size: 20, color: AppColors.eventPrimary(context)),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}
