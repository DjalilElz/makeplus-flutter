// lib/presentation/screens/participant/participant_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../logic/authentication/auth_bloc.dart';

class ParticipantProfileScreen extends StatefulWidget {
  const ParticipantProfileScreen({super.key});

  @override
  State<ParticipantProfileScreen> createState() =>
      _ParticipantProfileScreenState();
}

class _ParticipantProfileScreenState extends State<ParticipantProfileScreen> {
  late ApiClient _apiClient;
  List<Map<String, dynamic>> _myAteliers = [];
  bool _isLoadingAteliers = false;
  String? _qrCodeData;
  bool _isLoadingQrCode = true;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _loadQrCode();
  }

  Future<void> _loadQrCode() async {
    try {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id;

      if (userId == null) {
        setState(() => _isLoadingQrCode = false);
        return;
      }

      // Fetch participant's badge_id from my-ateliers endpoint
      final response = await _apiClient.get('/my-ateliers/');
      final participantData = response.data['participant'];

      if (participantData != null) {
        final badgeId = participantData['badge_id'] as String?;

        // Generate QR code in the new format: {"user_id": X, "badge_id": "..."}
        if (badgeId != null) {
          final qrData = '{"user_id": $userId, "badge_id": "$badgeId"}';
          setState(() {
            _qrCodeData = qrData;
            _isLoadingQrCode = false;
          });
        } else {
          setState(() => _isLoadingQrCode = false);
        }
      } else {
        setState(() => _isLoadingQrCode = false);
      }
    } catch (e) {
      print('❌ ERROR LOADING QR CODE: $e');
      setState(() => _isLoadingQrCode = false);
    }
  }

  Future<void> _loadMyAteliers([Function? onComplete]) async {
    setState(() {
      _isLoadingAteliers = true;
    });

    try {
      print('📚 LOADING MY ATELIERS');

      // Use the new dedicated endpoint that returns everything in one call
      final response = await _apiClient.get('/my-ateliers/');

      final data = response.data;
      final ateliersList = data['ateliers'] as List? ?? [];

      // Transform the response to match our UI needs
      final ateliers = ateliersList.map<Map<String, dynamic>>((atelier) {
        final room = atelier['room'] as Map<String, dynamic>?;
        return {
          'id': atelier['session_id'],
          'title': atelier['title'] ?? 'N/A',
          'speaker': atelier['speaker_name'] ?? 'N/A',
          'speaker_title': atelier['speaker_title'] ?? '',
          'room': room?['name'] ?? 'N/A',
          'time':
              _formatSessionTime(atelier['start_time'], atelier['end_time']),
          'start_time': atelier['start_time'],
          'end_time': atelier['end_time'],
          'status':
              _getSessionStatus(atelier['start_time'], atelier['end_time']),
          'description': atelier['description'] ?? '',
          'payment_status': atelier['payment_status'],
          'price': atelier['price'],
          'has_access': atelier['has_access'] ?? false,
        };
      }).toList();

      // Filter to show only paid and free ateliers (exclude pending)
      final accessibleAteliers = ateliers.where((atelier) {
        final paymentStatus = atelier['payment_status'];
        return paymentStatus == 'paid' || paymentStatus == 'free';
      }).toList();

      setState(() {
        _myAteliers = accessibleAteliers;
        _isLoadingAteliers = false;
      });

      print(
          '📚 LOADED ${_myAteliers.length} accessible ateliers (paid + free)');
      onComplete?.call();
    } catch (e) {
      print('❌ ERROR LOADING ATELIERS: $e');
      setState(() {
        _myAteliers = [];
        _isLoadingAteliers = false;
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

  void _showAteliersModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (builderContext, setModalState) {
            // Capture current state
            final isLoading = _isLoadingAteliers;
            final ateliers = _myAteliers;

            // Load ateliers on first open with callback to rebuild modal
            if (ateliers.isEmpty && !isLoading) {
              // Set loading state immediately before triggering the load
              Future.microtask(() {
                setState(() {
                  _isLoadingAteliers = true;
                });
                setModalState(() {});

                _loadMyAteliers(() {
                  // Rebuild modal when data is loaded
                  setModalState(() {});
                });
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mes Ateliers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                _loadMyAteliers(() {
                                  // Force modal to rebuild after data loads
                                  if (mounted) {
                                    setModalState(() {});
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ateliers.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Aucun atelier accessible',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Les ateliers payés et gratuits apparaîtront ici',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: ateliers.length,
                                    itemBuilder: (context, index) {
                                      final atelier = ateliers[index];
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
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Payment status badge (green for all accessible)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                  mainAxisSize:
                                                      MainAxisSize.min,
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Title
                                              Text(
                                                atelier['title'],
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
                                                  Text(
                                                    atelier['speaker'],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[700],
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
                                                  Text(
                                                    atelier['room'],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  const Icon(
                                                    Icons.access_time,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    atelier['time'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                  color: Colors.grey[600],
                                                  height: 1.4,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),

                                              // Payment status
                                              if (atelier['payment_status'] !=
                                                  null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
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
                                                                  : Colors
                                                                      .orange,
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

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primary,
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (user?.email != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    user!.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // QR code with loading state
              _isLoadingQrCode
                  ? Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
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
                onPressed: () => _showAteliersModal(context),
                icon: const Icon(Icons.meeting_room),
                label: const Text('Mes ateliers payants'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Scannez ce QR pour partager votre profil',
                style: TextStyle(color: Colors.grey),
              ),

              const Spacer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
