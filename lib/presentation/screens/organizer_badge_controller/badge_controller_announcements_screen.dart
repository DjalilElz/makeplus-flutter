// lib/presentation/screens/organizer_badge_controller/badge_controller_announcements_screen.dart

import 'package:flutter/material.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/services/announcement_service.dart';
import '../../../data/services/api_client.dart';
import '../../../routes/app_router.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class BadgeControllerAnnouncementsScreen extends StatefulWidget {
  const BadgeControllerAnnouncementsScreen({super.key});

  @override
  State<BadgeControllerAnnouncementsScreen> createState() =>
      _BadgeControllerAnnouncementsScreenState();
}

class _BadgeControllerAnnouncementsScreenState
    extends State<BadgeControllerAnnouncementsScreen> {
  late AnnouncementService _announcementService;
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _announcementService = AnnouncementService(ApiClient());
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AppLogger.d('📢 BADGE CONTROLLER - Loading announcements...');

      // Backend automatically filters announcements based on JWT token
      // No need to pass event_id parameter
      final announcements = await _announcementService.getAnnouncements();

      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });

      AppLogger.d(
          '📢 BADGE CONTROLLER - Loaded ${announcements.length} announcements');
    } catch (e) {
      AppLogger.d('❌ BADGE CONTROLLER - Error loading announcements: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RootTabPopScope(
      homeRoute: AppRouter.organizerBadgeControllerHome,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Annonces'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAnnouncements,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : _announcements.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAnnouncements,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _announcements.length,
                          itemBuilder: (context, index) {
                            final announcement = _announcements[index];
                            return _buildAnnouncementCard(announcement);
                          },
                        ),
                      ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 1, // Annonces tab
          userRole: 'organizer_badge_controller',
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(
                    context, AppRouter.organizerBadgeControllerHome);
                break;
              case 1:
                // Already on announcements
                break;
              case 2:
                Navigator.pushReplacementNamed(context, AppRouter.badgeScanner);
                break;
              case 3:
                Navigator.pushReplacementNamed(
                    context, AppRouter.badgeControllerProgram);
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 80,
            color: AppColors.textHint(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune annonce',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune annonce pour le moment',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Une erreur est survenue',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnnouncements,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    // Format timestamp
    final timeStr =
        '${announcement.createdAt.hour.toString().padLeft(2, '0')}:${announcement.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Show announcement details
          _showAnnouncementDetails(announcement);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.eventPrimary(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.campaign,
                      color: AppColors.eventPrimary(context),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and target
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: AppColors.textSecondary(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cible: ${announcement.targetLabel}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                announcement.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetails(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.people,
                      size: 16, color: AppColors.textSecondary(context)),
                  const SizedBox(width: 4),
                  Text(
                    'Cible: ${announcement.targetLabel}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: AppColors.textSecondary(context)),
                  const SizedBox(width: 4),
                  Text(
                    '${announcement.createdAt.day}/${announcement.createdAt.month}/${announcement.createdAt.year} à ${announcement.createdAt.hour.toString().padLeft(2, '0')}:${announcement.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              if (announcement.creatorName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person,
                        size: 16, color: AppColors.textSecondary(context)),
                    const SizedBox(width: 4),
                    Text(
                      'Créé par: ${announcement.creatorName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                announcement.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
