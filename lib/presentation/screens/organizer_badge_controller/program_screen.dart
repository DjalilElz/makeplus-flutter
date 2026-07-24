// lib/presentation/screens/organizer_badge_controller/program_screen.dart

import 'package:flutter/material.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../routes/app_router.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRoom = 'Salle 3';
  String _selectedThematic = 'Toutes les thématiques';
  String _selectedSpeakerType = 'Tous les conférenciers';

  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/organizer-badge-controller/home':
        return 0;
      case '/organizer-badge-controller/announcements':
        return 1;
      case '/organizer-badge-controller/badge-scanner':
        return 2;
      case '/organizer-badge-controller/program':
        return 3;
      case '/organizer-badge-controller/stats':
        return 4;
      default:
        return 3;
    }
  }

  final List<String> _rooms = [
    'Toutes les salles',
    'Salle 1',
    'Salle 2',
    'Salle 3',
    'Salle 4',
    'Salle 5',
    'Salle 6',
  ];

  final List<String> _thematics = [
    'Toutes les thématiques',
    'Santé',
    'Technologie',
    'Business',
    'Éducation',
    'Culture',
  ];

  final List<String> _speakerTypes = [
    'Tous les conférenciers',
    'Keynote Speaker',
    'Conférencier',
    'Panel',
    'Workshop',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Programme'),
      ),
      body: Column(
        children: [
          // Search and Filters Section
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.cardBackground(context),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Recherche …',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      // TODO: Implement search
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Filter Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _selectedRoom,
                        items: _rooms,
                        icon: Icons.meeting_room,
                        onChanged: (value) {
                          setState(() {
                            _selectedRoom = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _selectedThematic,
                        items: _thematics,
                        icon: Icons.category,
                        onChanged: (value) {
                          setState(() {
                            _selectedThematic = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _selectedSpeakerType,
                        items: _speakerTypes,
                        icon: Icons.person,
                        onChanged: (value) {
                          setState(() {
                            _selectedSpeakerType = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sessions Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.surfaceContainer(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '2 Sessions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderColor(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: AppColors.textSecondary(context)),
                      const SizedBox(width: 4),
                      Text(
                        'Par heure',
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
          ),

          // Sessions List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSessionCard(
                  speakerName: 'Dr. M. Ait',
                  category: 'Santé',
                  sessionType: 'Conférence',
                  title: 'Ouverture & Keynote',
                  time: '09:00–10:00',
                  room: 'SALLE 3',
                  status: 'En Cours',
                  statusColor: AppColors.success,
                ),
                const SizedBox(height: 16),
                _buildSessionCard(
                  speakerName: 'Dr. M. Ait',
                  category: 'Santé',
                  sessionType: 'Conférence',
                  title: 'Ouverture & Keynote',
                  time: '09:00–10:00',
                  room: 'SALLE 3',
                  status: 'En Cours',
                  statusColor: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _getCurrentIndex(context),
        userRole: 'organizer_badge_controller',
        onTap: (index) {
          // Navigate based on index
          switch (index) {
            case 0:
              // Home
              Navigator.pushReplacementNamed(
                  context, AppRouter.organizerBadgeControllerHome);
              break;
            case 1:
              // Announcements
              Navigator.pushReplacementNamed(context, AppRouter.announcements);
              break;
            case 2:
              // Scanner
              Navigator.pushReplacementNamed(context, AppRouter.badgeScanner);
              break;
            case 3:
              // Already on Program
              break;
            case 4:
              // Questions
              // TODO: Navigate to questions
              break;
          }
        },
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppColors.textPrimary(context)),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: AppColors.cardBackground(context),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.eventPrimary(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary(context),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSessionCard({
    required String speakerName,
    required String category,
    required String sessionType,
    required String title,
    required String time,
    required String room,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.eventPrimary(context).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.music_note,
                size: 48,
                color: AppColors.eventPrimary(context).withValues(alpha: 0.5),
              ),
            ),
          ),

          // Session Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Speaker Name
                Text(
                  speakerName,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Category and Session Type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.eventPrimary(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.eventPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sessionType,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Session Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),

                // Time and Room
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.meeting_room,
                      size: 16,
                      color: AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      room,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
