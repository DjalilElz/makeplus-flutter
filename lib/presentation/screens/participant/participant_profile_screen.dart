// lib/presentation/screens/participant/participant_profile_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class ParticipantProfileScreen extends StatefulWidget {
  const ParticipantProfileScreen({super.key});

  @override
  State<ParticipantProfileScreen> createState() =>
      _ParticipantProfileScreenState();
}

class _ParticipantProfileScreenState extends State<ParticipantProfileScreen> {
  late ApiClient _apiClient;
  List<Map<String, dynamic>> _myPaidItems = [];
  bool _isLoadingPaidItems = false;
  String? _qrCodeData;
  bool _isLoadingQrCode = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _loadProfileAndQrCode();
  }

  Future<void> _loadProfileAndQrCode() async {
    try {
      // Use /api/auth/me/ endpoint which returns complete profile + QR code
      final response = await _apiClient.get('/auth/me/').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      AppLogger.d('✅ PROFILE RESPONSE: ${response.data}');

      if (response.data != null) {
        final data = response.data;

        // Store profile data
        setState(() {
          _profileData = data;
        });

        // Extract QR code from response
        if (data['qr_code'] != null) {
          final qrCode = data['qr_code'];

          // ⚠️ CRITICAL: QR Code contains ONLY identification data
          // According to the new architecture, QR code should NOT contain payment data
          // Payment data is fetched fresh from database via API when controller scans
          final qrCodeIdentification = {
            'user_id': qrCode['user_id'],
            'badge_id': qrCode['badge_id'],
            'email': qrCode['email'],
            'first_name': qrCode['first_name'] ?? data['first_name'],
            'last_name': qrCode['last_name'] ?? data['last_name'],
          };

          // Encode ONLY identification data as JSON for scanning
          final qrString = jsonEncode(qrCodeIdentification);

          setState(() {
            _qrCodeData = qrString;
            _isLoadingQrCode = false;
          });

          AppLogger.d('✅ QR CODE LOADED with identification data only');
          AppLogger.d(
              '📋 QR Code contains: user_id, badge_id, email, first_name, last_name');
          AppLogger.d(
              '⚠️  Payment data NOT included (fetched from database when scanned)');
        } else {
          AppLogger.d('⚠️ No qr_code in profile response');
          setState(() => _isLoadingQrCode = false);
        }
      } else {
        AppLogger.d('⚠️ No data in profile response');
        setState(() => _isLoadingQrCode = false);
      }
    } catch (e) {
      AppLogger.d('❌ ERROR LOADING PROFILE AND QR CODE: $e');
      setState(() => _isLoadingQrCode = false);
    }
  }

  Future<void> _loadMyPaidItems([Function? onComplete]) async {
    if (!mounted) return;

    setState(() {
      _isLoadingPaidItems = true;
    });

    try {
      AppLogger.d('📚 LOADING MY PAID ITEMS');

      final response = await _apiClient.get('/auth/me/').timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      AppLogger.d('✅ PROFILE RESPONSE FOR PAID ITEMS: ${response.data}');

      final data = response.data;

      // ✅ FIXED: paid_items is in participant.qr_code_data.paid_items
      final participant = data['participant'] as Map<String, dynamic>?;
      final qrCodeData = participant?['qr_code_data'] as Map<String, dynamic>?;
      final paidItems = qrCodeData?['paid_items'] as List? ?? [];

      AppLogger.d('📦 PAID ITEMS: $paidItems');

      // Process ALL types of paid items (session, access, dinner, other)
      final List<Map<String, dynamic>> items = [];

      for (var item in paidItems) {
        final itemType = item['type'] as String?;

        if (itemType == 'session') {
          // For sessions, fetch full details
          try {
            final sessionId = item['id'];
            AppLogger.d('🔍 Fetching details for session: $sessionId');

            final sessionResponse =
                await _apiClient.get('/sessions/$sessionId/').timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Session fetch timeout');
              },
            );

            AppLogger.d('✅ Session details response: ${sessionResponse.data}');

            final sessionData = sessionResponse.data;
            final room = sessionData['room'] as Map<String, dynamic>?;

            items.add({
              'id': sessionData['id'],
              'type': 'session',
              'title': sessionData['title'] ?? item['title'] ?? 'N/A',
              'speaker': sessionData['speaker_name'] ?? 'N/A',
              'speaker_title': sessionData['speaker_title'] ?? '',
              'room': room?['name'] ?? 'N/A',
              'time': _formatSessionTime(
                  sessionData['start_time'], sessionData['end_time']),
              'start_time': sessionData['start_time'],
              'end_time': sessionData['end_time'],
              'status': _getSessionStatus(
                  sessionData['start_time'], sessionData['end_time']),
              'description': sessionData['description'] ?? '',
              'payment_status': item['payment_status'] ?? 'paid',
              'price': item['amount_paid'] ?? 0,
              'has_access': item['has_access'] ?? true,
            });

            AppLogger.d('✅ Added session with full details: ${sessionData['title']}');
          } catch (e) {
            AppLogger.d('⚠️ Failed to fetch session details for ${item['id']}: $e');
            // Fallback to basic info from paid_items
            items.add({
              'id': item['id'],
              'type': 'session',
              'title': item['title'] ?? 'N/A',
              'speaker': 'N/A',
              'speaker_title': '',
              'room': 'N/A',
              'time': 'N/A',
              'start_time': null,
              'end_time': null,
              'status': 'pas_encore',
              'description': '',
              'payment_status': item['payment_status'] ?? 'paid',
              'price': item['amount_paid'] ?? 0,
              'has_access': item['has_access'] ?? true,
            });
          }
        } else {
          // For other types (access, dinner, other), use basic info
          items.add({
            'id': item['id'],
            'type': itemType ?? 'other',
            'title': item['title'] ?? 'N/A',
            'description': '',
            'payment_status': item['payment_status'] ?? 'paid',
            'price': item['amount_paid'] ?? 0,
            'has_access': item['has_access'] ?? true,
          });
          AppLogger.d('✅ Added $itemType item: ${item['title']}');
        }
      }

      if (!mounted) return;

      setState(() {
        _myPaidItems = items;
        _isLoadingPaidItems = false;
      });

      AppLogger.d('📚 LOADED ${_myPaidItems.length} paid items');
      onComplete?.call();
    } catch (e) {
      AppLogger.d('❌ ERROR LOADING PAID ITEMS: $e');
      if (!mounted) return;

      setState(() {
        _myPaidItems = [];
        _isLoadingPaidItems = false;
      });
      onComplete?.call();
    }
  }

  String _getSessionStatus(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return 'pas_encore';

    try {
      final now = DateTime.now();
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);

      if (now.isBefore(start)) {
        return 'pas_encore';
      } else if (now.isAfter(end)) {
        return 'termine';
      } else {
        return 'en_cours';
      }
    } catch (e) {
      return 'pas_encore';
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

  void _showPaidItemsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        // Load data when modal opens if empty
        if (_myPaidItems.isEmpty && !_isLoadingPaidItems) {
          Future.delayed(Duration.zero, () => _loadMyPaidItems());
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Articles Payés',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            _loadMyPaidItems();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isLoadingPaidItems
                        ? const Center(child: CircularProgressIndicator())
                        : _myPaidItems.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 64,
                                      color: AppColors.textHint(context),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun atelier accessible',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Les ateliers payés et gratuits apparaîtront ici',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary(context),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _myPaidItems.length,
                                itemBuilder: (context, index) {
                                  final atelier = _myPaidItems[index];
                                  final paymentStatus =
                                      atelier['payment_status'];

                                  // All shown ateliers are accessible (paid or free)
                                  // Show green badge for all with appropriate label
                                  String statusLabel;
                                  IconData statusIcon;

                                  if (paymentStatus == 'free') {
                                    statusLabel = 'GRATUIT';
                                    statusIcon = Icons.card_giftcard;
                                  } else {
                                    statusLabel = 'PAYÉ';
                                    statusIcon = Icons.check_circle;
                                  }

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Payment status badge (green for all accessible)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            decoration: BoxDecoration(
                                              color: AppColors.success,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  statusIcon,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  statusLabel,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Title
                                          Text(
                                            atelier['title'],
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary(
                                                  context),
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Speaker
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.person,
                                                size: 16,
                                                color: AppColors.textSecondary(
                                                    context),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                atelier['speaker'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textSecondary(
                                                      context),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),

                                          // Room and time
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.meeting_room,
                                                size: 16,
                                                color: AppColors.textSecondary(
                                                    context),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                atelier['room'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textSecondary(
                                                      context),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: AppColors.textSecondary(
                                                    context),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                atelier['time'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.eventPrimary(context),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Description
                                          Text(
                                            atelier['description'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary(
                                                  context),
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          // Payment status
                                          if (atelier['payment_status'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 12),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    atelier['payment_status'] ==
                                                            'paid'
                                                        ? Icons.check_circle
                                                        : Icons.pending,
                                                    size: 16,
                                                    color:
                                                        atelier['payment_status'] ==
                                                                'paid'
                                                            ? Colors.green
                                                            : Colors.orange,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    atelier['payment_status'] ==
                                                            'paid'
                                                        ? 'Payé'
                                                        : 'En attente',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          atelier['payment_status'] ==
                                                                  'paid'
                                                              ? Colors.green
                                                              : Colors.orange,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;
    final name = user != null
        ? '${user.firstName} ${user.lastName}'.trim()
        : 'Participant';

    // Get badge ID from profile data if available
    String? badgeId;
    if (_profileData != null && _profileData!['qr_code'] != null) {
      badgeId = _profileData!['qr_code']['badge_id'];
    }

    return RootTabPopScope(
      homeRoute: '/participant/home',
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadProfileAndQrCode();
            },
            tooltip: 'Actualiser le profil',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.eventPrimary(context),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              if (user?.email != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    user!.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              if (badgeId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.eventPrimary(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Badge: $badgeId',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.eventPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // QR code with loading state.
              //
              // These boxes are deliberately always light grey, not theme-aware:
              // QrImageView renders black-on-white (required for scanner
              // contrast/reliability) regardless of app theme, so the loading
              // and unavailable placeholders match that fixed white backing
              // rather than flashing dark-then-white when the QR loads.
              _isLoadingQrCode
                  ? Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.eventPrimary(context),
                        ),
                      ),
                    )
                  : _qrCodeData != null
                      ? QrImageView(
                          data: _qrCodeData!,
                          version: QrVersions.auto,
                          size: 180,
                        )
                      : Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'QR code indisponible',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showPaidItemsModal(context),
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Mes articles payés'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Scannez ce QR pour partager votre profil',
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),

              const Spacer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        userRole: 'participant',
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/participant/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/participant/program');
              break;
            case 2:
              // Already on Profile
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/participant/guide');
              break;
            case 4:
              Navigator.pushReplacementNamed(
                  context, '/participant/announcements');
              break;
          }
        },
      ),
      ), // End Scaffold
    ); // End RootTabPopScope
  }
}
