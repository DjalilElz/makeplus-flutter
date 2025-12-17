// lib/presentation/screens/organizer/announcements_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../routes/app_router.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../data/services/announcement_service.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/services/api_client.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
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
      final authState = context.read<AuthBloc>().state;
      final eventId = authState.event?.id;

      print('📢 LOADING ANNOUNCEMENTS - Event ID: $eventId');

      // Backend automatically filters by user's current event
      // No need to pass event_id parameter
      final announcements = await _announcementService.getAnnouncements();
      print('📢 ANNOUNCEMENTS LOADED - Count: ${announcements.length}');
      for (var a in announcements) {
        print('  - ${a.title} (ID: ${a.id})');
      }

      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERROR LOADING ANNOUNCEMENTS: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCreateAnnouncementModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateAnnouncementModal(
        onAnnouncementCreated: _loadAnnouncements,
      ),
    );
  }

  void _showEditAnnouncementModal(AnnouncementModel announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateAnnouncementModal(
        announcement: announcement,
        onAnnouncementCreated: _loadAnnouncements,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine user role from route or pass as parameter
    final userRole =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'organizer';
    final isViewOnly = userRole == 'organizer_badge_controller';
    final currentIndex = 1; // Announcements is always at index 1 for both roles

    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonces'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnnouncements,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _announcements.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAnnouncements,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = _announcements[index];
                          return _buildAnnouncementCard(
                              announcement, isViewOnly);
                        },
                      ),
                    ),
      floatingActionButton: isViewOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: _showCreateAnnouncementModal,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle annonce'),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        userRole: userRole,
        onTap: (index) {
          // Navigate based on index and role
          if (userRole == 'organizer_badge_controller') {
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
          } else {
            // Original organizer room manager navigation
            switch (index) {
              case 0:
                // Home
                Navigator.pushReplacementNamed(
                    context, AppRouter.organizerRoomManagerHome);
                break;
              case 1:
                // Already on Announcements
                break;
              case 2:
                // Scanner (middle button)
                // TODO: Navigate to scanner
                break;
              case 3:
                // Rooms
                Navigator.pushReplacementNamed(context, AppRouter.roomsList);
                break;
              case 4:
                // Questions
                Navigator.pushReplacementNamed(context, AppRouter.questions);
                break;
            }
          }
        },
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
            'Créez votre première annonce',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement,
      [bool isViewOnly = false]) {
    final createdAt = announcement.createdAt;
    final timeStr =
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Could navigate to details if needed
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.campaign,
                      color: AppColors.primary,
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
                              'Cible: ${announcement.targetLabel}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeStr,
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
              const SizedBox(height: 12),
              // Message
              Text(
                announcement.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              // Actions (only show for room managers, not for badge controllers)
              if (!isViewOnly) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _showEditAnnouncementModal(announcement);
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        _showDeleteDialog(announcement.id);
                      },
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(String announcementId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette annonce ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _announcementService.deleteAnnouncement(announcementId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Annonce supprimée'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadAnnouncements();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// Create Announcement Modal
class CreateAnnouncementModal extends StatefulWidget {
  final AnnouncementModel? announcement;
  final VoidCallback onAnnouncementCreated;

  const CreateAnnouncementModal({
    super.key,
    this.announcement,
    required this.onAnnouncementCreated,
  });

  @override
  State<CreateAnnouncementModal> createState() =>
      _CreateAnnouncementModalState();
}

class _CreateAnnouncementModalState extends State<CreateAnnouncementModal> {
  String? _selectedType;
  String _selectedTarget = 'all';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  late AnnouncementService _announcementService;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _announcementService = AnnouncementService(ApiClient());

    // Pre-fill if editing
    if (widget.announcement != null) {
      _titleController.text = widget.announcement!.title;
      _messageController.text = widget.announcement!.description;
      _selectedTarget = widget.announcement!.target;
    }
  }

  final List<Map<String, dynamic>> _announcementTypes = [
    {
      'id': 'location',
      'label': 'Changement de salle',
      'icon': Icons.location_on,
      'color': AppColors.primary,
    },
    {
      'id': 'delay',
      'label': 'Retard \n',
      'icon': Icons.access_time,
      'color': AppColors.warning,
    },
    {
      'id': 'important',
      'label': 'Annonce importante',
      'icon': Icons.campaign,
      'color': AppColors.error,
    },
  ];

  final List<Map<String, String>> _targetOptions = [
    {'value': 'all', 'label': 'Tous'},
    {'value': 'participants', 'label': 'Participants'},
    {'value': 'exposants', 'label': 'Exposants'},
    {'value': 'gestionnaires', 'label': 'Gestionnaires'},
    {'value': 'controlleurs', 'label': 'Contrôleurs'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nouvelle annonce',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type selection
                      const Text(
                        'Type d\'annonce',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTypeSelection(),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'Titre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Entrez le titre de l\'annonce',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Message
                      const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Entrez le message détaillé',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Target selection
                      const Text(
                        'Cible',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTargetSelection(),
                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _titleController.text.isNotEmpty &&
                                  _messageController.text.isNotEmpty &&
                                  !_isSubmitting
                              ? _createAnnouncement
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.announcement != null
                                      ? 'Modifier l\'annonce'
                                      : 'Publier l\'annonce',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeSelection() {
    return Row(
      children: _announcementTypes.map((type) {
        final isSelected = _selectedType == type['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = type['id'];
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? type['color'].withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? type['color'] : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    type['icon'],
                    color: isSelected ? type['color'] : Colors.grey[600],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type['label'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? type['color'] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetSelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _targetOptions.map((target) {
        final isSelected = _selectedTarget == target['value'];
        return ChoiceChip(
          label: Text(target['label']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedTarget = target['value']!;
            });
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        );
      }).toList(),
    );
  }

  void _createAnnouncement() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      final eventId = authState.event?.id;

      if (eventId == null) {
        throw Exception('No event selected');
      }

      if (widget.announcement != null) {
        // Update existing announcement
        await _announcementService.updateAnnouncement(
          id: widget.announcement!.id,
          title: _titleController.text,
          description: _messageController.text,
          target: _selectedTarget,
        );
      } else {
        // Create new announcement
        print('📢 CREATING ANNOUNCEMENT - Event ID: $eventId');
        print('📢 Title: ${_titleController.text}');
        print('📢 Target: $_selectedTarget');

        await _announcementService.createAnnouncement(
          eventId: eventId,
          title: _titleController.text,
          description: _messageController.text,
          target: _selectedTarget,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.announcement != null
                  ? 'Annonce modifiée avec succès'
                  : 'Annonce publiée avec succès',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onAnnouncementCreated();
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
