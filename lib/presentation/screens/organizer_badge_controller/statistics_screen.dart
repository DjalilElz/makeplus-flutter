// lib/presentation/screens/organizer_badge_controller/statistics_screen.dart

import 'package:flutter/material.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../../routes/app_router.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ApiClient _apiClient;
  String _searchQuery = '';
  List<Map<String, dynamic>> _recentScans = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📊 LOADING ROOM STATISTICS');

      // Use my-room/statistics endpoint for controllers
      final response = await _apiClient.get('/my-room/statistics/');

      final data = response.data;

      setState(() {
        _statistics = data['statistics'] as Map<String, dynamic>?;
        _recentScans = data['recent_scans'] is List
            ? List<Map<String, dynamic>>.from(data['recent_scans'])
            : [];
        _isLoading = false;
      });

      print(
          '📊 LOADED STATISTICS: Total scans: ${_statistics?["total_scans"]}, Today: ${_statistics?["today_scans"]}');
      print('📊 RECENT SCANS: ${_recentScans.length} entries');
    } catch (e) {
      print('❌ ERROR LOADING STATISTICS: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredScans() {
    // Apply search filter on recent scans
    if (_searchQuery.isEmpty) {
      return _recentScans;
    }
    return _recentScans.where((scan) {
      final participant = scan['participant'] as Map<String, dynamic>?;
      final name = (participant?['name'] ?? '').toString().toLowerCase();
      final email = (participant?['email'] ?? '').toString().toLowerCase();
      final badgeId = (participant?['badge_id'] ?? '').toString().toLowerCase();
      final session = (scan['session'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          badgeId.contains(query) ||
          session.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredScans = _getFilteredScans();
    final totalScans = _statistics?['total_scans'] ?? 0;
    final todayScans = _statistics?['today_scans'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(
                  context, AppRouter.organizerBadgeControllerHome);
            }
          },
        ),
        title: const Text(
          'Statistiques',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Fixed Search Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un participant...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    // Scrollable Content (Stats + Participants)
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // Room Info Header with Stats
                          Container(
                            padding: const EdgeInsets.all(20),
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.meeting_room,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Salle 3',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Show statistics
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'Total Scannés',
                                        totalScans.toString(),
                                        AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Aujourd\'hui',
                                        todayScans.toString(),
                                        AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Recent Scans List
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredScans.length,
                            itemBuilder: (context, index) {
                              final scan = filteredScans[index];
                              final participant =
                                  scan['participant'] as Map<String, dynamic>?;
                              final name = participant?['name'] ?? 'N/A';
                              final email = participant?['email'] ?? '';
                              final session = scan['session'] ?? 'N/A';
                              final status = scan['status'] ?? 'unknown';
                              final accessedAt = scan['accessed_at'] ?? '';

                              // Parse name for avatar
                              final nameParts = name.split(' ');
                              final firstInitial = nameParts.isNotEmpty &&
                                      nameParts[0].isNotEmpty
                                  ? nameParts[0][0].toUpperCase()
                                  : 'P';

                              // Format timestamp
                              String formattedTime = '';
                              if (accessedAt.isNotEmpty) {
                                try {
                                  final dt = DateTime.parse(accessedAt);
                                  formattedTime =
                                      '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                } catch (e) {
                                  formattedTime = accessedAt;
                                }
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.1),
                                    child: Text(
                                      firstInitial,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (email.isNotEmpty)
                                        Text(
                                          email,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                          ),
                                        ),
                                      Text(
                                        'Session: $session',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (formattedTime.isNotEmpty)
                                        Text(
                                          formattedTime,
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: status == 'granted'
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status == 'granted'
                                          ? 'Accordé'
                                          : 'Refusé',
                                      style: TextStyle(
                                        color: status == 'granted'
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4, // Stats tab
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
              Navigator.pushReplacementNamed(context, AppRouter.badgeScanner);
              break;
            case 3:
              Navigator.pushReplacementNamed(
                  context, AppRouter.badgeControllerProgram);
              break;
            case 4:
              // Already on stats
              break;
          }
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
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
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Une erreur est survenue',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStatistics,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
