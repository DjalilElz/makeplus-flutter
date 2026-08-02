// lib/presentation/screens/organizer_badge_controller/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/page_cache_service.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../routes/app_router.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ApiClient _apiClient;
  bool _isSearching = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _recentScans = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _loadFromCacheThenRefresh();
  }

  void _loadFromCacheThenRefresh() {
    final eventId = context.read<AuthBloc>().state.event?.id;
    final cached = eventId == null
        ? null
        : PageCacheService.instance
            .get<_StatisticsCacheData>('badge_controller_stats_$eventId');
    if (cached != null) {
      _statistics = cached.statistics;
      _recentScans = cached.recentScans;
      _isLoading = false;
    }
    _loadStatistics(showSpinner: cached == null);
  }

  Future<void> _loadStatistics({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      AppLogger.d('📊 LOADING MY STATISTICS');

      // Use my-room/statistics endpoint - returns controller's own scans
      final response = await _apiClient.get('/my-room/statistics/');

      // Check if we got HTML instead of JSON (authentication failed)
      if (response.data is String &&
          (response.data as String).contains('<!DOCTYPE html>')) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }

      final data = response.data;
      AppLogger.d('📊 STATISTICS DATA: $data');

      // Handle response structure
      Map<String, dynamic>? statistics;
      List<Map<String, dynamic>> recentScans = [];

      if (data is Map<String, dynamic>) {
        statistics = data;

        // Parse recent_scans safely
        if (data.containsKey('recent_scans')) {
          final scansData = data['recent_scans'];
          if (scansData is List) {
            recentScans = scansData
                .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
                .toList();
          }
        }
      }

      if (!mounted) return;

      final eventId = context.read<AuthBloc>().state.event?.id;
      if (eventId != null) {
        PageCacheService.instance.set(
          'badge_controller_stats_$eventId',
          _StatisticsCacheData(statistics, recentScans),
        );
      }

      setState(() {
        _statistics = statistics;
        _recentScans = recentScans;
        _isLoading = false;
        _errorMessage = null;
      });

      AppLogger.d(
          '📊 LOADED STATISTICS: My check-ins today: ${_statistics?["my_check_ins_today"]}');
      AppLogger.d('📊 RECENT SCANS: ${_recentScans.length} entries');
    } catch (e, stackTrace) {
      AppLogger.d('❌ ERROR LOADING STATISTICS: $e');
      AppLogger.d('❌ STACK TRACE: $stackTrace');

      // Check if it's an authentication error
      final errorMsg = e.toString();
      if (errorMsg.contains('Session expirée') ||
          errorMsg.contains('401') ||
          errorMsg.contains('Unauthorized')) {
        // Redirect to login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      if (!mounted) return;
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
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredScans() {
    if (_searchQuery.isEmpty) {
      return _recentScans;
    }
    return _recentScans.where((scan) {
      final participant = scan['participant'] as Map<String, dynamic>?;
      final name = (participant?['name'] ?? '').toString().toLowerCase();
      final email = (participant?['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredScans = _getFilteredScans();
    final myCheckInsToday = _statistics?['my_check_ins_today'] ?? 0;

    return RootTabPopScope(
      homeRoute: AppRouter.organizerBadgeControllerHome,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Statistiques'),
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : Column(
                    children: [
                      if (_isSearching)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Rechercher un participant...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: AppColors.surfaceContainer(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
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
                      _buildTotalScansBar(myCheckInsToday),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () =>
                              _loadStatistics(showSpinner: false),
                          child: filteredScans.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.6,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.people_outline,
                                              size: 80,
                                              color:
                                                  AppColors.textHint(context),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _searchQuery.isEmpty
                                                  ? 'Aucun scan aujourd\'hui'
                                                  : 'Aucun résultat trouvé',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: AppColors
                                                    .textSecondary(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredScans.length,
                                  itemBuilder: (context, index) {
                                    return _buildScanCard(
                                        filteredScans[index]);
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 4,
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
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildTotalScansBar(dynamic myCheckInsToday) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.cardBackground(context),
      child: Row(
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 18,
            color: AppColors.eventPrimary(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Total Scans: $myCheckInsToday',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    final participant = scan['participant'] as Map<String, dynamic>?;
    final name = participant?['name'] ?? 'N/A';
    final email = participant?['email'] ?? '';
    final scannedAt = scan['scanned_at'] ?? '';

    final nameParts = name.split(' ');
    final firstInitial =
        nameParts.isNotEmpty && nameParts[0].isNotEmpty
            ? nameParts[0][0].toUpperCase()
            : 'P';

    String formattedTime = '';
    if (scannedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(scannedAt);
        formattedTime =
            '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedTime = scannedAt;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor:
              AppColors.eventPrimary(context).withValues(alpha: 0.1),
          child: Text(
            firstInitial,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.eventPrimary(context),
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (email.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 14,
                    color: AppColors.textSecondary(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      email,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (formattedTime.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
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
            onPressed: _loadStatistics,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _StatisticsCacheData {
  final Map<String, dynamic>? statistics;
  final List<Map<String, dynamic>> recentScans;

  _StatisticsCacheData(this.statistics, this.recentScans);
}
