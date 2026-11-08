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
import '../../widgets/stats/stats_widgets.dart';
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

      // Use my-room/statistics endpoint - returns controller's own scans,
      // for the event chosen at login (a controller can work on several).
      final currentEventId = context.read<AuthBloc>().state.event?.id;
      final response = await _apiClient.get(
        '/my-room/statistics/',
        queryParameters:
            currentEventId == null ? null : {'event_id': currentEventId},
      );

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
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _loadStatistics(showSpinner: false),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (_searchQuery.isEmpty) ...[
                                _buildTodaySummary(myCheckInsToday),
                                if (HourlyBarsCard.hasData(_hourlyToday)) ...[
                                  const SizedBox(height: 12),
                                  HourlyBarsCard(
                                    hourly: _hourlyToday,
                                    peak: _asMap(_statistics?['peak_today']),
                                    unit: 'scan',
                                  ),
                                ],
                                if (_asMap(_statistics?['totals']) != null) ...[
                                  const SizedBox(height: 12),
                                  _buildTotalsCard(
                                      _asMap(_statistics?['totals'])!),
                                ],
                                const SizedBox(height: 20),
                              ],
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  'Historique des scans',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                              ),
                              if (filteredScans.isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 64,
                                        color: AppColors.textHint(context),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'Aucun scan pour le moment'
                                            : 'Aucun résultat trouvé',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color:
                                              AppColors.textSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...filteredScans.map(_buildScanCard),
                            ],
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

  Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : null;

  Map<String, dynamic>? get _hourlyToday =>
      _asMap(_statistics?['hourly_today']);

  int _count(Map<String, dynamic>? map, String key) {
    final value = map?[key];
    return value is num ? value.toInt() : int.tryParse('${value ?? ''}') ?? 0;
  }

  /// Today's figures: scans, distinct people, and what the controller
  /// decided after each scan (Laisser entrer / Refuser l'accès).
  Widget _buildTodaySummary(dynamic myCheckInsToday) {
    final today = _asMap(_statistics?['today']);
    final distinct = _count(today, 'distinct');
    final undecided = _count(today, 'undecided');
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "CONTRÔLES EFFECTUÉS AUJOURD'HUI",
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$myCheckInsToday',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.eventPrimary(context),
              ),
            ),
            if (today != null)
              Text(
                '$distinct participant${distinct > 1 ? 's' : ''} distinct${distinct > 1 ? 's' : ''}',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary(context)),
              ),
            if (today != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '${_count(today, 'granted')}',
                      label: 'Laissés entrer',
                      icon: Icons.meeting_room_outlined,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      value: '${_count(today, 'denied')}',
                      label: 'Accès refusé',
                      icon: Icons.block,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '${_count(today, 'not_registered')}',
                      label: 'Non inscrits',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      value: '${_count(today, 'doubles')}',
                      label: 'Doubles scans',
                      icon: Icons.copy_all_outlined,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              if (undecided > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '$undecided scan${undecided > 1 ? 's' : ''} sans décision',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary(context)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(Map<String, dynamic> totals) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DEPUIS LE DÉBUT DE L'ÉVÉNEMENT",
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Decisions add up to the total (entered + refused +
                    // undecided); "non inscrits" is a badge status that can
                    // overlap them, so it comes last.
                    '${_count(totals, 'granted')} entrés · ${_count(totals, 'denied')} refusés · '
                    '${_count(totals, 'undecided')} sans décision · '
                    '${_count(totals, 'not_registered')} non inscrits',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textPrimary(context)),
                  ),
                ],
              ),
            ),
            Text(
              '${_count(totals, 'scans')}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.eventPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decisionChip(String? decision) {
    if (decision != 'granted' && decision != 'denied') {
      return const SizedBox.shrink();
    }
    final granted = decision == 'granted';
    final color = granted ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        granted ? 'Entré' : 'Refusé',
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    final participant = scan['participant'] as Map<String, dynamic>?;
    final name = participant?['name'] ?? 'N/A';
    final email = participant?['email'] ?? '';
    final scannedAt = scan['scanned_at'] ?? '';

    final nameParts = name.split(' ');
    final firstInitial = nameParts.isNotEmpty && nameParts[0].isNotEmpty
        ? nameParts[0][0].toUpperCase()
        : 'P';

    String formattedTime = '';
    if (scannedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(scannedAt).toLocal();
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
        trailing: _decisionChip(scan['access_decision']?.toString()),
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
            if (scan['status'] == 'not_registered')
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  'Non inscrit à cet événement',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
