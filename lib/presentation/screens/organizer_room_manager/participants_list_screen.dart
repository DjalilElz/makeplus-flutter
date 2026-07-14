// lib/presentation/screens/organizer_room_manager/participants_list_screen.dart

import 'package:flutter/material.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../routes/app_router.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

class ParticipantsListScreen extends StatefulWidget {
  const ParticipantsListScreen({super.key});

  @override
  State<ParticipantsListScreen> createState() => _ParticipantsListScreenState();
}

class _ParticipantsListScreenState extends State<ParticipantsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock data - replace with real data from your backend
  final List<Map<String, String>> _allParticipants = List.generate(
    50,
    (index) => {
      'name': 'Amina BENDJEBBAR ${index + 1}',
      'role': 'Participant Salle ${(index % 6) + 1} - Conférencier',
      'time': '08:0${index % 10}',
    },
  );

  List<Map<String, String>> get _filteredParticipants {
    if (_searchQuery.isEmpty) {
      return _allParticipants;
    }
    return _allParticipants.where((participant) {
      return participant['name']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          participant['role']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RootTabPopScope(
      homeRoute: AppRouter.organizerRoomManagerHome,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Suivi des participants'),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                border: Border(
                  bottom: BorderSide(color: AppColors.borderColor(context)),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un participant...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Results count
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredParticipants.length} participant(s)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    Text(
                      'Filtré(s) sur ${_allParticipants.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                ],
              ),
            ),

            // Participants List
            Expanded(
              child: _filteredParticipants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.textHint(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun participant trouvé',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredParticipants.length,
                      itemBuilder: (context, index) {
                        final participant = _filteredParticipants[index];
                        return _buildParticipantCard(
                          participant['name']!,
                          participant['role']!,
                          participant['time']!,
                        );
                      },
                    ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 2, // Rooms/Salle position
          userRole: 'organizer',
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(
                    context, AppRouter.organizerRoomManagerHome);
                break;
              case 1:
                Navigator.pushReplacementNamed(
                    context, AppRouter.announcements);
                break;
              case 2:
                // Navigate to rooms list
                Navigator.pushReplacementNamed(context, AppRouter.roomsList);
                break;
              case 3:
                Navigator.pushReplacementNamed(context, AppRouter.questions);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildParticipantCard(String name, String role, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Text(
            name[0],
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(role),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to participant detail page
        },
      ),
    );
  }
}
