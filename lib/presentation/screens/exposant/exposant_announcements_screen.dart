// lib/presentation/screens/exposant/exposant_announcements_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class ExposantAnnouncementsScreen extends StatefulWidget {
  const ExposantAnnouncementsScreen({super.key});

  @override
  State<ExposantAnnouncementsScreen> createState() =>
      _ExposantAnnouncementsScreenState();
}

class _ExposantAnnouncementsScreenState
    extends State<ExposantAnnouncementsScreen> {
  late ApiClient _apiClient;
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      final eventId = authState.event?.id;

      if (eventId == null) {
        throw Exception('No event selected');
      }

      final response = await _apiClient.get(
        '/annonces/',
        queryParameters: {'event_id': eventId},
      );

      final data = response.data;
      final results =
          data is Map && data.containsKey('results') ? data['results'] : data;

      setState(() {
        _announcements = results is List
            ? List<Map<String, dynamic>>.from(
                results.map((item) => Map<String, dynamic>.from(item)))
            : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: ${e.toString()}';
        _isLoading = false;
      });
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
      case 'controlleurs':
        return Icons.qr_code_scanner;
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
        return AppColors.primary;
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
      case '/exposant/plan':
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
    return WillPopScope(
      onWillPop: () async {
        // Navigate to home instead of quitting
        Navigator.pushReplacementNamed(context, '/exposant/home');
        return false;
      },
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
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = _announcements[index];
                          return _buildAnnouncementCard(announcement);
                        },
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
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
                color: Colors.grey[500],
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune annonce',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune annonce pour le moment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final target = announcement['target'] ?? '';
    final icon = _getIconForTarget(target);
    final color = _getColorForTarget(target);
    final timestamp = _formatTimestamp(announcement['created_at']);

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
                    color: color.withOpacity(0.1),
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
                        announcement['title'] ?? 'Sans titre',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cible: $target',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timestamp,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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
              announcement['description'] ?? announcement['message'] ?? '',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
