// lib/presentation/screens/exposant/exposant_stats_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/exposant_scan_service.dart';
import '../../../data/models/exposant_scan_model.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class ExposantStatsScreen extends StatefulWidget {
  const ExposantStatsScreen({super.key});

  @override
  State<ExposantStatsScreen> createState() => _ExposantStatsScreenState();
}

class _ExposantStatsScreenState extends State<ExposantStatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late ExposantScanService _exposantScanService;

  List<ExposantScanModel> _scannedParticipants = [];
  int _totalVisits = 0;
  int _todayVisits = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _exposantScanService = ExposantScanService(apiClient);
    _loadScans();
  }

  Future<void> _loadScans() async {
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

        setState(() {
          _scannedParticipants = result['scans'] as List<ExposantScanModel>;
          _totalVisits = result['total_visits'] as int;
          _todayVisits = result['today_visits'] as int;
          _isLoading = false;
        });
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
      case '/exposant/plan':
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
        const SnackBar(
          content: Row(
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
              Text('Génération du fichier Excel...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 30),
        ),
      );

      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Permission de stockage requise pour enregistrer le fichier'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }

      // Call the backend to get Excel file bytes
      final fileBytes = await _exposantScanService.exportToExcel();

      if (!mounted) return;

      // Get the Downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception('Impossible de trouver le dossier de téléchargement');
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now();
      final filename =
          'Statistiques_Visiteurs_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.xlsx';
      final filePath = '${downloadsDir.path}/$filename';

      // Write the file
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (!mounted) return;

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success message with file path
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fichier Excel enregistré avec succès!\n$filePath',
          ),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
          duration: const Duration(seconds: 6),
        ),
      );
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/exposant/home');
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Statistiques',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                        Text(_errorMessage!,
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadScans,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // Statistics Cards
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Visiteurs total',
                                  _totalVisits.toString(),
                                  AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Aujourd\'hui',
                                  _todayVisits.toString(),
                                  AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 8),
                      ),

                      // Search Bar - Fixed/Sticky
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SearchBarDelegate(
                          searchController: _searchController,
                          searchQuery: _searchQuery,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          onClear: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 8),
                      ),

                      // Participants List Header
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(
                            'Liste des visiteurs (${_filteredParticipants.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Participants List
                      _filteredParticipants.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun visiteur trouvé',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final participant =
                                        _filteredParticipants[index];
                                    return _buildParticipantCard(participant);
                                  },
                                  childCount: _filteredParticipants.length,
                                ),
                              ),
                            ),
                    ],
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _exportToExcel,
          backgroundColor: AppColors.success,
          icon: const Icon(Icons.file_download),
          label: const Text('Exporter'),
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
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  scan.participantName ?? 'Participant',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (scan.participantEmail != null) ...[
            Row(
              children: [
                Icon(Icons.email, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    scan.participantEmail!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    scan.formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (scan.notes != null && scan.notes!.isNotEmpty)
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      scan.notes!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Sticky Search Bar Delegate
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onChanged;
  final VoidCallback onClear;

  _SearchBarDelegate({
    required this.searchController,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  double get minExtent =>
      69.0; // 45 height + 12 vertical padding + 12 bottom padding

  @override
  double get maxExtent => 69.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: 45,
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un visiteur...',
            hintStyle: const TextStyle(fontSize: 14),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: onClear,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) {
    return searchQuery != oldDelegate.searchQuery;
  }
}
