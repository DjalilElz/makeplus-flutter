// lib/presentation/screens/participant/diffusion_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../logic/authentication/auth_bloc.dart';

class DiffusionScreen extends StatefulWidget {
  const DiffusionScreen({super.key});

  @override
  State<DiffusionScreen> createState() => _DiffusionScreenState();
}

class _DiffusionScreenState extends State<DiffusionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiClient _apiClient;

  List<Map<String, dynamic>> _conferences = [];
  List<Map<String, dynamic>> _ateliers = [];
  bool _isLoadingConferences = true;
  bool _isLoadingAteliers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiClient = ApiClient();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final authState = context.read<AuthBloc>().state;
      final eventId = authState.event?.id;

      if (eventId == null) {
        print('⚠️ NO EVENT ID');
        setState(() {
          _isLoadingConferences = false;
          _isLoadingAteliers = false;
        });
        return;
      }

      print('📡 LOADING SESSIONS for event: $eventId');

      // Load all sessions
      final response = await _apiClient.get(
        '/sessions/',
        queryParameters: {'event_id': eventId},
      );

      final sessionsList = response.data['results'] as List? ?? [];
      print('📚 FETCHED ${sessionsList.length} sessions');

      // Get participant's accessible ateliers
      List<String> accessibleAtelierIds = [];
      try {
        final ateliersResponse = await _apiClient.get('/my-ateliers/');
        print('📦 RAW MY-ATELIERS RESPONSE: ${ateliersResponse.data}');

        final ateliersList = ateliersResponse.data['ateliers'] as List? ?? [];

        // Filter to only include paid/free ateliers (backend filter not working yet)
        final accessibleAteliers = ateliersList.where((a) {
          final paymentStatus = a['payment_status'] as String?;
          final hasAccess = a['has_access'] as bool? ?? false;

          // Only include if paid, free, OR has_access is true
          return paymentStatus == 'paid' ||
              paymentStatus == 'free' ||
              hasAccess == true;
        }).toList();

        accessibleAtelierIds =
            accessibleAteliers.map((a) => a['session_id'] as String).toList();

        print('📊 TOTAL ATELIERS IN RESPONSE: ${ateliersList.length}');
        print('✅ PAID/FREE ATELIERS: ${accessibleAteliers.length}');
        print('✅ ACCESSIBLE ATELIER IDs: $accessibleAtelierIds');

        // Show which ones were filtered out
        final filteredOut = ateliersList.length - accessibleAteliers.length;
        if (filteredOut > 0) {
          print('⛔ FILTERED OUT: $filteredOut pending ateliers');
        }
      } catch (e) {
        print('⚠️ ERROR LOADING ACCESSIBLE ATELIERS: $e');
      }

      // Separate into conferences and ateliers
      final conferences = <Map<String, dynamic>>[];
      final ateliers = <Map<String, dynamic>>[];

      print('\n🔍 PROCESSING SESSIONS:');
      for (var session in sessionsList) {
        final sessionType = session['session_type'] as String?;
        final sessionId = session['id'] as String;
        final roomData = session['room'];
        final youtubeUrl = session['youtube_live_url'] as String?;

        // Handle room - can be String, Map, or room_name field
        String roomName = 'N/A';
        if (session['room_name'] != null && session['room_name'] is String) {
          // Use room_name if available (from /my-ateliers/)
          roomName = session['room_name'];
        } else if (roomData is Map<String, dynamic>) {
          // Extract name from room object
          roomName = roomData['name'] ?? 'N/A';
        } else if (roomData is String) {
          // room might be a string (room name or UUID)
          roomName = roomData;
        }

        print(
            '  Session: ${session['title']} (Type: $sessionType, ID: $sessionId, Room: $roomName, YouTube: ${youtubeUrl != null ? "YES" : "NO"})');

        final sessionData = {
          'id': sessionId,
          'title': session['title'] ?? 'N/A',
          'speaker': session['speaker_name'] ?? 'N/A',
          'room': roomName,
          'time': _formatSessionTime(
            session['start_time'],
            session['end_time'],
          ),
          'isLive': session['is_live'] ?? false,
          'description': session['description'] ?? '',
          'youtubeUrl': youtubeUrl ?? '',
          'hasLiveStream': youtubeUrl != null && youtubeUrl.isNotEmpty,
          'start_time': session['start_time'],
          'end_time': session['end_time'],
        };

        if (sessionType == 'conference') {
          // All conferences are accessible
          conferences.add(sessionData);
          print('  ➕ Conference: ${session['title']}');
        } else if (sessionType == 'atelier') {
          // Only show accessible ateliers
          if (accessibleAtelierIds.isEmpty) {
            // If we don't have accessible ateliers list, show all ateliers
            ateliers.add(sessionData);
            print('  ➕ Atelier (no filter): ${session['title']}');
          } else if (accessibleAtelierIds.contains(sessionId)) {
            ateliers.add(sessionData);
            print('  ➕ Atelier: ${session['title']}');
          } else {
            print(
                '  ⛔ Atelier not accessible: ${session['title']} (ID: $sessionId)');
          }
        } else {
          print(
              '  ⚠️ Unknown session type: $sessionType for ${session['title']}');
        }
      }

      setState(() {
        _conferences = conferences;
        _ateliers = ateliers;
        _isLoadingConferences = false;
        _isLoadingAteliers = false;
      });

      print('✅ CONFERENCES: ${conferences.length}');
      print('✅ ACCESSIBLE ATELIERS: ${ateliers.length}');
    } catch (e) {
      print('❌ ERROR LOADING SESSIONS: $e');
      setState(() {
        _isLoadingConferences = false;
        _isLoadingAteliers = false;
      });
    }
  }

  String _formatSessionTime(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return 'N/A';

    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);

      return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sessions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Conférences'),
            Tab(text: 'Ateliers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionsList(_conferences, _isLoadingConferences),
          _buildSessionsList(_ateliers, _isLoadingAteliers),
        ],
      ),
    );
  }

  Widget _buildSessionsList(
      List<Map<String, dynamic>> sessions, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune session disponible',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les sessions de cet événement apparaîtront ici',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final bool isLive = session['isLive'] ?? false;
    final bool hasLiveStream = session['hasLiveStream'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/participant/session-detail',
            arguments: session,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live indicator or No Stream indicator
              Row(
                children: [
                  if (isLive && hasLiveStream)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 8,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'EN DIRECT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!hasLiveStream)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.videocam_off,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'PAS DE DIFFUSION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Title
              Text(
                session['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Speaker
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      session['speaker'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Room and time
              Row(
                children: [
                  const Icon(
                    Icons.meeting_room,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      session['room'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    session['time'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                session['description'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Action button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/participant/session-detail',
                      arguments: session,
                    );
                  },
                  icon: Icon(
                    hasLiveStream
                        ? (isLive ? Icons.play_circle_filled : Icons.videocam)
                        : Icons.info_outline,
                    size: 18,
                  ),
                  label: Text(
                    hasLiveStream
                        ? (isLive ? 'Regarder' : 'Voir la diffusion')
                        : 'Voir détails',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
