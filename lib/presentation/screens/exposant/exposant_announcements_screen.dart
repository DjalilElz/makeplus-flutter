// lib/presentation/screens/exposant/exposant_announcements_screen.dart

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

class ExposantAnnouncementsScreen extends StatefulWidget {
  const ExposantAnnouncementsScreen({super.key});

  @override
  State<ExposantAnnouncementsScreen> createState() =>
      _ExposantAnnouncementsScreenState();
}

class _ExposantAnnouncementsScreenState
    extends State<ExposantAnnouncementsScreen> {
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
            .get<List<AnnouncementModel>>('exposant_announcements_$eventId');
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
      AppLogger.d('📢 EXPOSANT - Loading announcements...');

      // Backend automatically filters announcements based on JWT token
      // No need to pass event_id parameter
      final announcements = await _announcementService.getAnnouncements();

      AppLogger.d('📢 EXPOSANT - Loaded ${announcements.length} announcements');

      if (!mounted) return;

      final eventId = context.read<AuthBloc>().state.event?.id;
      if (eventId != null) {
        PageCacheService.instance
            .set('exposant_announcements_$eventId', announcements);
      }

      setState(() {
        _announcements = announcements;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      AppLogger.d('❌ EXPOSANT - Error loading announcements: $e');
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

  Color _getColorForTarget(BuildContext context, String target) {
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
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RootTabPopScope(
      homeRoute: '/exposant/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Annonces'),
          elevation: 0,
          actions: [
            if (!_isLoading)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadAnnouncements,
                tooltip: 'Actualiser',
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
                        onRefresh: () => _loadAnnouncements(showSpinner: false),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _announcements.length,
                          itemBuilder: (context, index) {
                            final announcement = _announcements[index];
                            return _buildAnnouncementCard(
                                context, announcement);
                          },
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
                Navigator.pushReplacementNamed(context, '/exposant/plan');
                break;
              case 2:
                Navigator.pushNamed(context, '/exposant/scanner');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/exposant/stats');
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.textHint(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAnnouncements,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
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

  Widget _buildAnnouncementCard(
      BuildContext context, AnnouncementModel announcement) {
    final target = announcement.target;
    final icon = _getIconForTarget(target);
    final color = _getColorForTarget(context, target);
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
