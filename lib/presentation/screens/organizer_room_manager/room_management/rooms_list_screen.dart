// lib/presentation/screens/organizer_room_manager/room_management/rooms_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/theme/app_colors.dart';
import '../../../../logic/authentication/auth_bloc.dart';
import '../../../../data/services/room_service.dart';
import '../../../../data/services/session_service.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/models/room_model.dart';
import '../../../widgets/navigation/bottom_nav_bar.dart';
import '../../../../routes/app_router.dart';

class RoomsListScreen extends StatefulWidget {
  const RoomsListScreen({super.key});

  @override
  State<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends State<RoomsListScreen> {
  final int _currentIndex = 3; // Salles tab
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _showSearchBar = true;
  double _lastScrollOffset = 0;

  late RoomService _roomService;
  late SessionService _sessionService;

  RoomModel? _assignedRoom;
  List<SessionModel> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _roomService = RoomService(ApiClient());
    _sessionService = SessionService(ApiClient());
    _loadRoomsAndSessions();

    // Add scroll listener for search bar visibility
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadRoomsAndSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      final eventId = authState.event?.id;
      final userId = authState.user?.id;

      if (eventId == null || userId == null) {
        throw Exception('No event or user selected');
      }

      print('🏢 LOADING ASSIGNED ROOM - Event ID: $eventId, User ID: $userId');

      // Fetch the user's assigned room from room assignments
      final assignedRoom = await _roomService.getAssignedRoom(
        userId: userId.toString(),
        eventId: eventId,
      );

      if (assignedRoom == null) {
        throw Exception('Aucune salle assignée pour cet utilisateur');
      }

      // Load sessions for the assigned room only
      final sessions = await _sessionService.getSessions(
        eventId: eventId,
        roomId: assignedRoom.id,
      );

      setState(() {
        _assignedRoom = assignedRoom;
        _sessions = sessions;
        _isLoading = false;
      });

      print(
          '🏢 LOADED room: ${assignedRoom.name} with ${sessions.length} sessions');
    } catch (e) {
      print('❌ ERROR LOADING ROOM/SESSIONS: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;

    // Hide search bar when scrolling down, show when scrolling up
    if (currentOffset > _lastScrollOffset && currentOffset > 50) {
      // Scrolling down
      if (_showSearchBar) {
        setState(() {
          _showSearchBar = false;
        });
      }
    } else if (currentOffset < _lastScrollOffset) {
      // Scrolling up
      if (!_showSearchBar) {
        setState(() {
          _showSearchBar = true;
        });
      }
    }

    _lastScrollOffset = currentOffset;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Salles'),
          backgroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Salles'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Erreur de chargement',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRoomsAndSessions,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_assignedRoom == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Salles'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.meeting_room_outlined,
                  size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Aucune salle assignée',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('Vous n\'êtes assigné à aucune salle',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: false,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Rechercher une session...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search, color: Colors.grey),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Salles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRoomsAndSessions,
        child: _buildSessionsList(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        userRole: 'organizer',
        onTap: (index) {
          // Navigate based on index
          switch (index) {
            case 0:
              // Home
              Navigator.pushReplacementNamed(
                  context, AppRouter.organizerRoomManagerHome);
              break;
            case 1:
              // Announcements
              Navigator.pushReplacementNamed(context, AppRouter.announcements);
              break;
            case 2:
              // Scanner (middle button)
              // TODO: Navigate to scanner
              break;
            case 3:
              // Already on Salles
              break;
            case 4:
              // Questions
              Navigator.pushReplacementNamed(context, AppRouter.questions);
              break;
          }
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    final filteredSessions = _getFilteredSessions();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.meeting_room,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _assignedRoom!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Capacité: ${_assignedRoom!.capacity} personnes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.event_note, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${filteredSessions.length} sessions programmées',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<SessionModel> _getFilteredSessions() {
    // Sessions are already filtered by room in _loadRoomsAndSessions
    // Just apply search query if exists
    if (_searchQuery.isEmpty) {
      return _sessions;
    }

    return _sessions.where((session) {
      final title = session.title.toLowerCase();
      final speaker = (session.speakerName ?? '').toLowerCase();
      final type = session.sessionType.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) ||
          speaker.contains(query) ||
          type.contains(query);
    }).toList();
  }

  Widget _buildSessionsList() {
    final filteredSessions = _getFilteredSessions();

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: filteredSessions.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeaderSection();
        }

        final session = filteredSessions[index - 1];
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: index == filteredSessions.length ? 16 : 0,
            top: index == 1 ? 16 : 16,
          ),
          child: _buildSessionCard(session),
        );
      },
    );
  }

  Widget _buildSessionCard(SessionModel session) {
    // Format time
    final startTime =
        '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${session.endTime.hour.toString().padLeft(2, '0')}:${session.endTime.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge and title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: session.sessionType == 'atelier'
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    session.sessionType == 'atelier' ? 'Atelier' : 'Conférence',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: session.sessionType == 'atelier'
                          ? Colors.orange[800]
                          : Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    session.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Speaker and time
            if (session.speakerName != null) ...[
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      session.speakerName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '$startTime - $endTime',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status buttons
            Row(
              children: [
                Expanded(
                  child: _buildStatusButton(
                    session.id,
                    'Pas encore',
                    SessionStatus.notStarted,
                    session.status == SessionStatus.notStarted,
                    Colors.grey[600]!,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusButton(
                    session.id,
                    'En cours',
                    SessionStatus.inProgress,
                    session.status == SessionStatus.inProgress,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusButton(
                    session.id,
                    'Terminé',
                    SessionStatus.finished,
                    session.status == SessionStatus.finished,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    String sessionId,
    String label,
    SessionStatus targetStatus,
    bool isActive,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _updateSessionStatus(sessionId, targetStatus),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color : Colors.grey[300]!,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateSessionStatus(
      String sessionId, SessionStatus targetStatus) async {
    try {
      print(
          '🔄 UPDATING SESSION STATUS - ID: $sessionId, Status: $targetStatus');

      SessionModel updatedSession;
      if (targetStatus == SessionStatus.inProgress) {
        // Start session
        updatedSession = await _sessionService.startSession(sessionId);
      } else if (targetStatus == SessionStatus.finished) {
        // End session
        updatedSession = await _sessionService.endSession(sessionId);
      } else {
        // Cancel/reset session
        updatedSession = await _sessionService.cancelSession(sessionId);
      }

      // Update local state
      setState(() {
        final index = _sessions.indexWhere((s) => s.id == sessionId);
        if (index != -1) {
          _sessions[index] = updatedSession;
        }
      });

      print('✅ SESSION STATUS UPDATED');
    } catch (e) {
      print('❌ ERROR UPDATING SESSION STATUS: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Add Session Modal
class AddSessionModal extends StatefulWidget {
  const AddSessionModal({super.key});

  @override
  State<AddSessionModal> createState() => _AddSessionModalState();
}

class _AddSessionModalState extends State<AddSessionModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeSlotController = TextEditingController();

  String? _selectedSpeaker;
  String? _selectedRoom;
  String? _selectedTheme;
  XFile? _coverPhoto;

  final List<String> _speakers = [
    'Dr M. Ait',
    'Prof. Benali',
    'Dr. Amrani',
    'M. Khalil',
  ];

  final List<String> _rooms = [
    'Salle N°1',
    'Salle N°2',
    'Salle N°3',
    'Salle N°4',
    'Salle N°5',
  ];

  final List<String> _themes = [
    'Santé',
    'Technologie',
    'Innovation',
    'Business',
    'Education',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _timeSlotController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      // Check file size (2MB = 2097152 bytes)
      final fileSize = await image.length();
      if (fileSize > 2097152) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La photo ne doit pas dépasser 2MB'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() {
        _coverPhoto = image;
      });
    }
  }

  Future<void> _pickTimeSlot() async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (startTime != null && mounted) {
      final TimeOfDay? endTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: (startTime.hour + 1) % 24,
          minute: startTime.minute,
        ),
      );

      if (endTime != null) {
        setState(() {
          _timeSlotController.text =
              '${startTime.format(context)} - ${endTime.format(context)}';
        });
      }
    }
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
                      'Ajouter une session',
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
                          hintText: 'Titre de la session',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Speaker
                      const Text(
                        'Intervenant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _selectedSpeaker,
                        hint: 'Sélectionner un intervenant',
                        items: _speakers,
                        onChanged: (value) {
                          setState(() {
                            _selectedSpeaker = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Room
                      const Text(
                        'Salle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _selectedRoom,
                        hint: 'Sélectionner une salle',
                        items: _rooms,
                        onChanged: (value) {
                          setState(() {
                            _selectedRoom = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Theme
                      const Text(
                        'Thème',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown(
                        value: _selectedTheme,
                        hint: 'Sélectionner un thème',
                        items: _themes,
                        onChanged: (value) {
                          setState(() {
                            _selectedTheme = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Time slot
                      const Text(
                        'Horaire',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _timeSlotController,
                        readOnly: true,
                        onTap: _pickTimeSlot,
                        decoration: InputDecoration(
                          hintText: '11:00 - 12:00',
                          suffixIcon: const Icon(Icons.access_time),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Cover photo
                      const Text(
                        'Photo de couverture',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _coverPhoto != null
                              ? Stack(
                                  children: [
                                    Center(
                                      child: Text(
                                        'Image sélectionnée: ${_coverPhoto!.name}',
                                        style: const TextStyle(
                                            color: AppColors.primary),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          setState(() {
                                            _coverPhoto = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Cliquez pour ajouter une photo',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Max 2MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _titleController.text.isNotEmpty &&
                                  _selectedSpeaker != null &&
                                  _selectedRoom != null &&
                                  _selectedTheme != null &&
                                  _timeSlotController.text.isNotEmpty
                              ? _createSession
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Ajouter une session',
                            style: TextStyle(
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

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(hint),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _createSession() {
    // TODO: Create session via BLoC
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session créée avec succès'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
