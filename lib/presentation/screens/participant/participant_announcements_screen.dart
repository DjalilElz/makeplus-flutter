// lib/presentation/screens/participant/participant_announcements_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/services/announcement_service.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/page_cache_service.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class ParticipantAnnouncementsScreen extends StatefulWidget {
  const ParticipantAnnouncementsScreen({super.key});

  @override
  State<ParticipantAnnouncementsScreen> createState() =>
      _ParticipantAnnouncementsScreenState();
}

class _ParticipantAnnouncementsScreenState
    extends State<ParticipantAnnouncementsScreen> {
  late AnnouncementService _announcementService;
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _announcementService = AnnouncementService(ApiClient());
    _loadFromCacheThenRefresh();
  }

  void _loadFromCacheThenRefresh() {
    final eventId = context.read<AuthBloc>().state.event?.id;
    final cached = eventId == null
        ? null
        : PageCacheService.instance
            .get<List<AnnouncementModel>>('participant_announcements_$eventId');
    if (cached != null) {
      _announcements = cached;
      _isLoading = false;
    }
    _loadAnnouncements(showSpinner: cached == null);
  }

  Future<void> _loadAnnouncements({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      AppLogger.d('📢 PARTICIPANT - Loading announcements...');

      // Backend automatically filters announcements based on JWT token
      // No need to pass event_id parameter
      final announcements = await _announcementService.getAnnouncements();

      AppLogger.d(
          '📢 PARTICIPANT - Loaded ${announcements.length} announcements');

      if (!mounted) return;

      final eventId = context.read<AuthBloc>().state.event?.id;
      if (eventId != null) {
        PageCacheService.instance
            .set('participant_announcements_$eventId', announcements);
      }

      setState(() {
        _announcements = announcements;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      AppLogger.d('❌ PARTICIPANT - Error loading announcements: $e');
      if (!mounted) return;
      if (showSpinner) {
        setState(() {
          _errorMessage = 'Erreur de chargement: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  IconData _getIconForTarget(String target) {
    switch (target.toLowerCase()) {
      case 'all':
      case 'tous':
        return Icons.campaign;
      case 'participants':
        return Icons.people;
      case 'exposants':
        return Icons.store;
      case 'controller':
      case 'controlleurs':
        return Icons.qr_code_scanner;
      case 'gestionnaire':
      case 'gestionnaires':
        return Icons.meeting_room;
      default:
        return Icons.info;
    }
  }

  Color _getColorForTarget(String target) {
    switch (target.toLowerCase()) {
      case 'all':
      case 'tous':
        return AppColors.error;
      case 'participants':
        return AppColors.eventPrimary(context);
      case 'exposants':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  String _formatTimestamp(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'maintenant';
      }
    } catch (e) {
      return '';
    }
  }

  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/participant/home':
        return 0;
      case '/participant/program':
        return 1;
      case '/participant/profile':
        return 2;
      case '/participant/guide':
        return 3;
      case '/participant/announcements':
        return 4;
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RootTabPopScope(
      homeRoute: '/participant/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Annonces'),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _loadAnnouncements(showSpinner: false),
                child: _errorMessage != null
                    ? _buildErrorState()
                    : _announcements.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _announcements.length,
                            itemBuilder: (context, index) {
                              final announcement = _announcements[index];
                              return _buildAnnouncementCard(announcement);
                            },
                          ),
              ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _getCurrentIndex(context),
          userRole: 'participant',
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/participant/home');
                break;
              case 1:
                Navigator.pushReplacementNamed(context, '/participant/program');
                break;
              case 2:
                Navigator.pushReplacementNamed(context, '/participant/profile');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/participant/guide');
                break;
              case 4:
                // Already on Annonces
                break;
            }
          },
        ),
      ),
    );
  }

  // Wrapped in a scrollable (not just Center) so RefreshIndicator's drag
  // gesture is recognized even though the message is short enough not to
  // overflow the viewport on its own.
  Widget _buildScrollableMessage({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 80, color: AppColors.textHint(context)),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(height: 16),
                        action,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState() {
    return _buildScrollableMessage(
      icon: Icons.error_outline,
      title: 'Erreur',
      message: _errorMessage ?? 'Une erreur est survenue',
      action: ElevatedButton.icon(
        onPressed: _loadAnnouncements,
        icon: const Icon(Icons.refresh),
        label: const Text('Réessayer'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildScrollableMessage(
      icon: Icons.campaign_outlined,
      title: 'Aucune annonce',
      message: 'Aucune annonce pour le moment',
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    final target = announcement.target;
    final icon = _getIconForTarget(target);
    final color = _getColorForTarget(target);
    final timestamp = _formatTimestamp(announcement.createdAt.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
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
                            'Cible: $target',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timestamp,
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
            const SizedBox(height: 16),
            // Message
            Text(
              announcement.description,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
