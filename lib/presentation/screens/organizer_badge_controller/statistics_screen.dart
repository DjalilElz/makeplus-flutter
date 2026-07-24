// lib/presentation/screens/organizer_badge_controller/statistics_screen.dart

import 'package:flutter/material.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
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

      setState(() {
        _statistics = statistics;
        _recentScans = recentScans;
        _isLoading = false;
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
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          badgeId.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredScans = _getFilteredScans();
    final myCheckInsToday = _statistics?['my_check_ins_today'] ?? 0;
    final successfulScansToday = _statistics?['successful_scans_today'] ?? 0;

    return RootTabPopScope(
      homeRoute: AppRouter.organizerBadgeControllerHome,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Statistiques'),
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
                : CustomScrollView(
                    slivers: [
                      // Statistics Cards - Collapsible
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          color: AppColors.cardBackground(context),
                          child: Row(
                            children: [
                              // Total Scans Card
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.qr_code_scanner,
                                  label: 'Total Scans',
                                  value: myCheckInsToday.toString(),
                                  color: AppColors.eventPrimary(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Successful Scans Card
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.check_circle,
                                  label: 'Réussis',
                                  value: successfulScansToday.toString(),
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 8),
                      ),
                      // Search Bar - Pinned
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SearchBarDelegate(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            color: AppColors.cardBackground(context),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Rechercher un participant...',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 8),
                      ),
                      // Scanned Participants List
                      filteredScans.isEmpty
                          ? SliverFillRemaining(
                              child: Container(
                                color: AppColors.background(context),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 80,
                                        color: AppColors.textHint(context),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'Aucun scan aujourd\'hui'
                                            : 'Aucun résultat trouvé',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final scan = filteredScans[index];
                                    final participant = scan['participant']
                                        as Map<String, dynamic>?;
                                    final name = participant?['name'] ?? 'N/A';
                                    final email = participant?['email'] ?? '';
                                    final badgeId =
                                        participant?['badge_id'] ?? '';
                                    final status = scan['status'] ?? 'unknown';
                                    final scannedAt = scan['scanned_at'] ?? '';
                                    final errorMessage = scan['error_message'];
                                    final totalPaidItems =
                                        scan['total_paid_items'] ?? 0;
                                    final totalAmount =
                                        scan['total_amount'] ?? 0.0;

                                    // Parse name for avatar
                                    final nameParts = name.split(' ');
                                    final firstInitial = nameParts.isNotEmpty &&
                                            nameParts[0].isNotEmpty
                                        ? nameParts[0][0].toUpperCase()
                                        : 'P';

                                    // Format timestamp
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

                                    // Determine status display
                                    String statusText;
                                    Color statusColor;
                                    IconData statusIcon;

                                    switch (status) {
                                      case 'success':
                                        statusText = 'Réussi';
                                        statusColor = AppColors.success;
                                        statusIcon = Icons.check_circle;
                                        break;
                                      case 'not_registered':
                                        statusText = 'Non inscrit';
                                        statusColor = AppColors.warning;
                                        statusIcon = Icons.warning;
                                        break;
                                      case 'error':
                                        statusText = 'Erreur';
                                        statusColor = AppColors.error;
                                        statusIcon = Icons.error;
                                        break;
                                      default:
                                        statusText = 'Inconnu';
                                        statusColor = AppColors.textHint(context);
                                        statusIcon = Icons.help;
                                    }

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(12),
                                        leading: CircleAvatar(
                                          radius: 28,
                                          backgroundColor: AppColors.eventPrimary(context)
                                              .withValues(alpha: 0.1),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            if (email.isNotEmpty)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.email_outlined,
                                                    size: 14,
                                                    color: AppColors
                                                        .textSecondary(context),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      email,
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .textSecondary(
                                                                context),
                                                        fontSize: 12,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (badgeId.isNotEmpty)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.badge_outlined,
                                                    size: 14,
                                                    color: AppColors
                                                        .textSecondary(context),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    badgeId,
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary(
                                                              context),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (status == 'success' &&
                                                totalPaidItems > 0)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .shopping_cart_outlined,
                                                    size: 14,
                                                    color: AppColors
                                                        .textSecondary(context),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$totalPaidItems items - ${totalAmount.toStringAsFixed(0)} DA',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary(
                                                              context),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (errorMessage != null &&
                                                errorMessage.isNotEmpty)
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.info_outline,
                                                    size: 14,
                                                    color: AppColors.warning,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      errorMessage,
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors.warning,
                                                        fontSize: 11,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                                    color: AppColors
                                                        .textSecondary(context),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    formattedTime,
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary(
                                                              context),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                                alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                statusIcon,
                                                color: statusColor,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                statusText,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: filteredScans.length,
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
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

// Custom delegate for pinned search bar
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchBarDelegate({required this.child});

  @override
  double get minExtent => 80.0;

  @override
  double get maxExtent => 80.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) {
    return false;
  }
}
