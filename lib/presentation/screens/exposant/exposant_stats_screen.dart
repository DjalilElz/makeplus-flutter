// lib/presentation/screens/exposant/exposant_stats_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/models/exposant_scan_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/exposant_scan_service.dart';
import '../../../data/services/page_cache_service.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class ExposantStatsScreen extends StatefulWidget {
  const ExposantStatsScreen({super.key});

  @override
  State<ExposantStatsScreen> createState() => _ExposantStatsScreenState();
}

class _ExposantStatsScreenState extends State<ExposantStatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  late ExposantScanService _exposantScanService;

  List<ExposantScanModel> _scannedParticipants = [];
  int _totalVisits = 0;
  int _todayVisits = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Cache management
  DateTime? _lastLoadTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  bool get _isCacheValid {
    if (_lastLoadTime == null) return false;
    return DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration;
  }

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _exposantScanService = ExposantScanService(apiClient);
    _loadFromCacheThenRefresh();
  }

  void _loadFromCacheThenRefresh() {
    final eventId = context.read<AuthBloc>().state.event?.id;
    final cached = eventId == null
        ? null
        : PageCacheService.instance
            .get<_ExposantStatsCacheData>('exposant_stats_$eventId');
    if (cached != null) {
      _scannedParticipants = cached.scans;
      _totalVisits = cached.totalVisits;
      _todayVisits = cached.todayVisits;
      _lastLoadTime = cached.loadedAt;
    }
    // Reuses the screen's own 5-minute freshness window: if the cached
    // data is still fresh, _loadScans below will skip the network call
    // entirely instead of just skipping the spinner.
    _loadScans();
  }

  Future<void> _loadScans({bool forceRefresh = false}) async {
    // If cache is valid and not forcing refresh, skip loading
    if (!forceRefresh && _isCacheValid && _scannedParticipants.isNotEmpty) {
      AppLogger.d('📦 CACHE HIT - Using cached stats data');
      return;
    }

    AppLogger.d('🔄 LOADING - Fetching fresh stats data from API');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;

      if (authState.status == AuthStatus.authenticated &&
          authState.event != null) {
        final result = await _exposantScanService.getMyScans(
          eventId: authState.event!.id,
        );

        if (!mounted) return;

        final scans = result['scans'] as List<ExposantScanModel>;
        final totalVisits = result['total_visits'] as int;
        final todayVisits = result['today_visits'] as int;
        final loadedAt = DateTime.now();

        PageCacheService.instance.set(
          'exposant_stats_${authState.event!.id}',
          _ExposantStatsCacheData(scans, totalVisits, todayVisits, loadedAt),
        );

        setState(() {
          _scannedParticipants = scans;
          _totalVisits = totalVisits;
          _todayVisits = todayVisits;
          _lastLoadTime = loadedAt;
          _isLoading = false;
        });

        AppLogger.d('✅ CACHE UPDATED - Stats data cached at $_lastLoadTime');
      } else {
        setState(() {
          _errorMessage = 'Événement non sélectionné';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: ${e.toString()}';
        _isLoading = false;
      });
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
        return 3;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExposantScanModel> get _filteredParticipants {
    if (_searchQuery.isEmpty) {
      return _scannedParticipants;
    }
    return _scannedParticipants.where((scan) {
      final name = scan.participantName?.toLowerCase() ?? '';
      final email = scan.participantEmail?.toLowerCase() ?? '';
      final badge = scan.participantBadge?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          badge.contains(query);
    }).toList();
  }

  void _exportToExcel() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Preparation du fichier...'),
            ],
          ),
          backgroundColor: AppColors.eventPrimary(context),
          duration: const Duration(seconds: 30),
        ),
      );

      // Call the backend to get Excel file bytes
      final fileBytes = await _exposantScanService.exportToExcel();

      if (!mounted) return;

      // Generate filename with timestamp
      final timestamp = DateTime.now();
      final filename =
          'Statistiques_Visiteurs_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.xlsx';

      // Save file to temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (!mounted) return;

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Share using native share sheet
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: 'Statistiques des visiteurs du stand',
          subject: 'Export Excel - Statistiques',
        ),
      );

      if (!mounted) return;

      // Show result message and reload data
      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fichier partage avec succes'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        // Reload data after successful share
        _loadScans(forceRefresh: true);
      } else if (result.status == ShareResultStatus.dismissed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partage annule'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'export: ${e.toString()}'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: _exportToExcel,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredParticipants = _filteredParticipants;

    return RootTabPopScope(
      homeRoute: '/exposant/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Statistiques',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: AppColors.textHint(context)),
                        const SizedBox(height: 16),
                        Text(_errorMessage!,
                            style: TextStyle(
                                color: AppColors.textSecondary(context))),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadScans(forceRefresh: true),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      if (_isSearching)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Rechercher un visiteur...',
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
                      Container(
                        color: AppColors.cardBackground(context),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'Visiteurs total',
                                _totalVisits.toString(),
                                AppColors.eventPrimary(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'Aujourd\'hui',
                                _todayVisits.toString(),
                                AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        color: AppColors.cardBackground(context),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'Liste des visiteurs (${filteredParticipants.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _loadScans(forceRefresh: true),
                          child: filteredParticipants.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.5,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.search_off,
                                              size: 64,
                                              color:
                                                  AppColors.textHint(context),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Aucun visiteur trouvé',
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
                                  itemCount: filteredParticipants.length,
                                  itemBuilder: (context, index) {
                                    return _buildParticipantCard(
                                        filteredParticipants[index]);
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _exportToExcel,
          backgroundColor: AppColors.success,
          icon: const Icon(Icons.share),
          label: const Text('Partager'),
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
                Navigator.pushReplacementNamed(context, '/exposant/guide');
                break;
              case 2:
                Navigator.pushNamed(context, '/exposant/scanner');
                break;
              case 3:
                // Already on stats
                break;
              case 4:
                Navigator.pushReplacementNamed(
                    context, '/exposant/announcements');
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(ExposantScanModel scan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.eventPrimary(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.eventPrimary(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  scan.participantName ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (scan.participantEmail != null) ...[
            Row(
              children: [
                Icon(Icons.email,
                    size: 14, color: AppColors.textSecondary(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    scan.participantEmail!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 14, color: AppColors.textSecondary(context)),
              const SizedBox(width: 6),
              Text(
                scan.formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExposantStatsCacheData {
  final List<ExposantScanModel> scans;
  final int totalVisits;
  final int todayVisits;
  final DateTime loadedAt;

  _ExposantStatsCacheData(
      this.scans, this.totalVisits, this.todayVisits, this.loadedAt);
}
