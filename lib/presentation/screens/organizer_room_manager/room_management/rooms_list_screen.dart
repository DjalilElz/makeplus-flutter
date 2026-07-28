// lib/presentation/screens/organizer_room_manager/room_management/rooms_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/theme/app_colors.dart';
import '../../../../data/models/room_model.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/page_cache_service.dart';
import '../../../../data/services/room_service.dart';
import '../../../../data/services/session_service.dart';
import '../../../../logic/authentication/auth_bloc.dart';
import '../../../../routes/app_router.dart';
import '../../../widgets/navigation/bottom_nav_bar.dart';
import '../../../widgets/navigation/root_tab_pop_scope.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class RoomsListScreen extends StatefulWidget {
  const RoomsListScreen({super.key});

  @override
  State<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends State<RoomsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isSearching = false;

  late RoomService _roomService;
  late SessionService _sessionService;

  RoomModel? _assignedRoom;
  List<SessionModel> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Session swapping state
  String? _selectedSessionId;
  bool _isSwapping = false;
  @override
  void initState() {
    super.initState();
    _roomService = RoomService(ApiClient());
    _sessionService = SessionService(ApiClient());
    _loadFromCacheThenRefresh();
  }

  void _loadFromCacheThenRefresh() {
    final authState = context.read<AuthBloc>().state;
    final eventId = authState.event?.id;
    final userId = authState.user?.id;
    final cachedRoom = eventId == null
        ? null
        : PageCacheService.instance
            .get<RoomModel>('rooms_list_room_${eventId}_$userId');
    final cachedSessions = eventId == null
        ? null
        : PageCacheService.instance
            .get<List<SessionModel>>('rooms_list_sessions_${eventId}_$userId');
    final hasCachedData = cachedRoom != null && cachedSessions != null;
    if (hasCachedData) {
      _assignedRoom = cachedRoom;
      _sessions = cachedSessions;
      _isLoading = false;
    }
    _loadRoomsAndSessions(showSpinner: !hasCachedData);
  }

  Future<void> _loadRoomsAndSessions({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authState = context.read<AuthBloc>().state;
      final eventId = authState.event?.id;
      final userId = authState.user?.id;

      if (eventId == null || userId == null) {
        throw Exception('No event or user selected');
      }

      AppLogger.d(
          '🏢 LOADING ASSIGNED ROOM - Event ID: $eventId, User ID: $userId');

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

      PageCacheService.instance
          .set('rooms_list_room_${eventId}_$userId', assignedRoom);
      PageCacheService.instance
          .set('rooms_list_sessions_${eventId}_$userId', sessions);

      if (!mounted) return;
      setState(() {
        _assignedRoom = assignedRoom;
        _sessions = sessions;
        _isLoading = false;
        _errorMessage = null;
      });

      AppLogger.d(
          '🏢 LOADED room: ${assignedRoom.name} with ${sessions.length} sessions');
    } catch (e) {
      AppLogger.d('❌ ERROR LOADING ROOM/SESSIONS: $e');
      if (!mounted) return;
      // Only surface the error when there's nothing cached to fall back on;
      // a failed background refresh should leave the visible data alone.
      if (showSpinner) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
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
      return RootTabPopScope(
        homeRoute: AppRouter.organizerRoomManagerHome,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(''), // Empty title while loading
            elevation: 1,
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 2, // Salle tab
            userRole: 'organizer',
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(
                      context, AppRouter.organizerRoomManagerHome);
                  break;
                case 1:
                  Navigator.pushReplacementNamed(
                      context, AppRouter.announcements);
                  break;
                case 2:
                  // Already on Salles
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, AppRouter.questions);
                  break;
              }
            },
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return RootTabPopScope(
        homeRoute: AppRouter.organizerRoomManagerHome,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(''),
            elevation: 1,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: AppColors.textHint(context)),
                const SizedBox(height: 16),
                Text('Erreur de chargement',
                    style: TextStyle(
                        fontSize: 18, color: AppColors.textSecondary(context))),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(_errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary(context))),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadRoomsAndSessions,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 2, // Salle tab
            userRole: 'organizer',
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(
                      context, AppRouter.organizerRoomManagerHome);
                  break;
                case 1:
                  Navigator.pushReplacementNamed(
                      context, AppRouter.announcements);
                  break;
                case 2:
                  // Already on Salles
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, AppRouter.questions);
                  break;
              }
            },
          ),
        ),
      );
    }

    if (_assignedRoom == null) {
      return RootTabPopScope(
        homeRoute: AppRouter.organizerRoomManagerHome,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(''),
            elevation: 1,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.meeting_room_outlined,
                    size: 64, color: AppColors.textHint(context)),
                const SizedBox(height: 16),
                Text('Aucune salle assignée',
                    style: TextStyle(
                        fontSize: 18, color: AppColors.textSecondary(context))),
                const SizedBox(height: 8),
                Text('Vous n\'êtes assigné à aucune salle',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary(context))),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 2, // Salle tab
            userRole: 'organizer',
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(
                      context, AppRouter.organizerRoomManagerHome);
                  break;
                case 1:
                  Navigator.pushReplacementNamed(
                      context, AppRouter.announcements);
                  break;
                case 2:
                  // Already on Salles
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, AppRouter.questions);
                  break;
              }
            },
          ),
        ),
      );
    }
    return RootTabPopScope(
      homeRoute: AppRouter.organizerRoomManagerHome,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            _assignedRoom?.name ?? 'Salles',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 1,
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadRoomsAndSessions(showSpinner: false),
          child: Column(
            children: [
              // Search bar (when active)
              if (_isSearching)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderColor(context)),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une session...',
                      prefixIcon: Icon(Icons.search,
                          color: AppColors.eventPrimary(context)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              Expanded(child: _buildSessionsList()),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 2, // Salle tab (index 2 in new 4-item navbar)
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
                Navigator.pushReplacementNamed(
                    context, AppRouter.announcements);
                break;
              case 2:
                // Already on Salles
                break;
              case 3:
                // Questions/Settings
                Navigator.pushReplacementNamed(context, AppRouter.questions);
                break;
            }
          },
        ),
      ),
    );
  }

  List<SessionModel> _getFilteredSessions() {
    // Sessions are already filtered by room in _loadRoomsAndSessions
    // Just apply search query if exists
    List<SessionModel> filteredList;

    if (_searchQuery.isEmpty) {
      filteredList = _sessions;
    } else {
      filteredList = _sessions.where((session) {
        final title = session.title.toLowerCase();
        final speaker = (session.speakerName ?? '').toLowerCase();
        final type = session.sessionType.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) ||
            speaker.contains(query) ||
            type.contains(query);
      }).toList();
    }

    // Sort by start time (earliest to latest)
    filteredList.sort((a, b) => a.startTime.compareTo(b.startTime));

    return filteredList;
  }

  Widget _buildSessionsList() {
    final filteredSessions = _getFilteredSessions();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredSessions.length,
      itemBuilder: (context, index) {
        final session = filteredSessions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSessionCard(session),
        );
      },
    );
  }

  // Helper method to get session type display info
  Map<String, dynamic> _getSessionTypeInfo(String sessionType) {
    switch (sessionType.toLowerCase()) {
      case 'conference':
        return {
          'label': 'Conférence',
          'color': const Color(0xFF3B82F6), // Blue
          'bgColor': const Color(0xFF3B82F6).withValues(alpha: 0.15),
        };
      case 'atelier':
        return {
          'label': 'Atelier',
          'color': const Color(0xFFF97316), // Orange
          'bgColor': const Color(0xFFF97316).withValues(alpha: 0.15),
        };
      case 'table_ronde':
        return {
          'label': 'Table Ronde',
          'color': const Color(0xFF8B5CF6), // Purple
          'bgColor': const Color(0xFF8B5CF6).withValues(alpha: 0.15),
        };
      case 'communication':
        return {
          'label': 'Communication',
          'color': const Color(0xFF10B981), // Green
          'bgColor': const Color(0xFF10B981).withValues(alpha: 0.15),
        };
      case 'symposium':
        return {
          'label': 'Symposium',
          'color': const Color(0xFFEC4899), // Pink
          'bgColor': const Color(0xFFEC4899).withValues(alpha: 0.15),
        };
      case 'lunch_symposium':
        return {
          'label': 'Lunch Symposium',
          'color': const Color(0xFFF59E0B), // Amber
          'bgColor': const Color(0xFFF59E0B).withValues(alpha: 0.15),
        };
      case 'session_photo_communication':
        return {
          'label': 'Session Photo',
          'color': const Color(0xFF06B6D4), // Cyan
          'bgColor': const Color(0xFF06B6D4).withValues(alpha: 0.15),
        };
      default:
        return {
          'label': sessionType,
          'color': const Color(0xFF6B7280), // Gray
          'bgColor': const Color(0xFF6B7280).withValues(alpha: 0.15),
        };
    }
  }

  Widget _buildSessionCard(SessionModel session) {
    // Format date and time
    final dateFormat = DateFormat('EEE, dd MMM yyyy');
    final timeFormat = DateFormat('HH:mm');

    final sessionDate = dateFormat.format(session.startTime);
    final startTime = timeFormat.format(session.startTime);
    final endTime = timeFormat.format(session.endTime);

    // Get session type info
    final typeInfo = _getSessionTypeInfo(session.sessionType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: _selectedSessionId == session.id ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedSessionId == session.id
              ? AppColors.eventPrimary(context)
              : AppColors.borderColor(context),
          width: _selectedSessionId == session.id ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _selectedSessionId == session.id
              ? AppColors.eventPrimary(context).withValues(alpha: 0.05)
              : AppColors.cardBackground(context),
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
                      color: typeInfo['bgColor'],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      typeInfo['label'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: typeInfo['color'],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      session.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  // Swap icon button -- disabled while a swap is already in
                  // flight so a second tap can't fire an overlapping request.
                  IconButton(
                    icon: _isSwapping && _selectedSessionId == session.id
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.eventPrimary(context),
                            ),
                          )
                        : Icon(
                            _selectedSessionId == session.id
                                ? Icons.check_circle
                                : Icons.swap_horiz,
                            color: _selectedSessionId == session.id
                                ? AppColors.success
                                : AppColors.textSecondary(context),
                          ),
                    onPressed: _isSwapping
                        ? null
                        : () => _toggleSessionSelection(session),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Speaker and date/time
              if (session.speakerName != null) ...[
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: AppColors.textSecondary(context)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        session.speakerName!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: AppColors.textSecondary(context)),
                  const SizedBox(width: 6),
                  Text(
                    sessionDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Time
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: AppColors.textSecondary(context)),
                  const SizedBox(width: 6),
                  Text(
                    '$startTime - $endTime',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
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
                      AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusButton(
                      session.id,
                      'En cours',
                      SessionStatus.inProgress,
                      session.status == SessionStatus.inProgress,
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusButton(
                      session.id,
                      'Terminé',
                      SessionStatus.finished,
                      session.status == SessionStatus.finished,
                      AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Questions
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRouter.sessionQuestions,
                    arguments: {
                      'sessionId': session.id,
                      'sessionTitle': session.title,
                    },
                  ),
                  icon: const Icon(Icons.question_answer_outlined, size: 18),
                  label: const Text('Questions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.eventPrimary(context),
                    side: BorderSide(color: AppColors.eventPrimary(context)),
                  ),
                ),
              ),
            ],
          ),
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
            color: isActive ? color : AppColors.surfaceContainer(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color : AppColors.borderColor(context),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isActive ? Colors.white : AppColors.textSecondary(context),
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
      AppLogger.d(
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

      AppLogger.d('✅ SESSION STATUS UPDATED');
    } catch (e) {
      AppLogger.d('❌ ERROR UPDATING SESSION STATUS: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Toggle session selection for swapping
  void _toggleSessionSelection(SessionModel session) {
    setState(() {
      if (_selectedSessionId == session.id) {
        // Deselect if clicking the same session
        _selectedSessionId = null;
      } else if (_selectedSessionId == null) {
        // First selection
        _selectedSessionId = session.id;
      } else {
        // Second selection - show confirmation dialog
        final firstSession =
            _sessions.firstWhere((s) => s.id == _selectedSessionId);
        _showSwapConfirmationDialog(firstSession, session);
      }
    });
  }

  // Show confirmation dialog before swapping
  void _showSwapConfirmationDialog(
      SessionModel session1, SessionModel session2) {
    final startTime1 =
        '${session1.startTime.hour.toString().padLeft(2, '0')}:${session1.startTime.minute.toString().padLeft(2, '0')}';
    final endTime1 =
        '${session1.endTime.hour.toString().padLeft(2, '0')}:${session1.endTime.minute.toString().padLeft(2, '0')}';
    final startTime2 =
        '${session2.startTime.hour.toString().padLeft(2, '0')}:${session2.startTime.minute.toString().padLeft(2, '0')}';
    final endTime2 =
        '${session2.endTime.hour.toString().padLeft(2, '0')}:${session2.endTime.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Échanger les horaires ?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voulez-vous échanger les horaires de ces sessions ?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session1.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$startTime1 - $endTime1',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Icon(Icons.swap_vert,
                        color: AppColors.eventPrimary(context), size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    session2.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$startTime2 - $endTime2',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedSessionId = null; // Clear selection
              });
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _swapSessionTimes(session1.id, session2.id);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // Swap session times via API
  Future<void> _swapSessionTimes(String session1Id, String session2Id) async {
    setState(() {
      _isSwapping = true;
    });

    try {
      AppLogger.d('🔄 SWAPPING SESSION TIMES - IDs: $session1Id, $session2Id');

      // Call API endpoint
      final result =
          await _sessionService.swapSessionTimes(session1Id, session2Id);

      if (result['success'] == true) {
        // Update sessions from API response
        final swappedSessions = result['sessions'] as List;

        setState(() {
          for (var sessionData in swappedSessions) {
            final updatedSession = SessionModel.fromJson(sessionData);
            final index =
                _sessions.indexWhere((s) => s.id == updatedSession.id);
            if (index != -1) {
              _sessions[index] = updatedSession;
            }
          }
          _selectedSessionId = null; // Clear selection
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Horaires échangés avec succès'),
            backgroundColor: AppColors.success,
          ),
        );

        AppLogger.d('✅ SESSION TIMES SWAPPED SUCCESSFULLY');
      } else {
        throw Exception(result['message'] ?? 'Failed to swap sessions');
      }
    } catch (e) {
      AppLogger.d('❌ ERROR SWAPPING SESSION TIMES: $e');

      if (!mounted) return;
      setState(() {
        _selectedSessionId = null; // Clear selection on error
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSwapping = false;
      });
    }
  }
}
