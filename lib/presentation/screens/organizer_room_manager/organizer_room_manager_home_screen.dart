// lib/presentation/screens/organizer_room_manager/organizer_room_manager_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../../routes/app_router.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

class OrganizerRoomManagerHomeScreen extends StatefulWidget {
  const OrganizerRoomManagerHomeScreen({super.key});

  @override
  State<OrganizerRoomManagerHomeScreen> createState() =>
      _OrganizerRoomManagerHomeScreenState();
}

class _OrganizerRoomManagerHomeScreenState
    extends State<OrganizerRoomManagerHomeScreen> {
  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/organizer-room-manager/home':
        return 0;
      case '/organizer-room-manager/announcements':
        return 1;
      case '/organizer-room-manager/participants':
        return 2;
      case '/organizer-room-manager/rooms':
        return 3;
      case '/organizer-room-manager/settings':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        final event = authState.event;

        return RootTabPopScope(
          homeRoute: AppRouter.organizerRoomManagerHome,
          isHome: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'Accueil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Header
                        _buildEventHeader(user, event),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: _getCurrentIndex(context),
              userRole: 'organizer',
              onTap: (index) {
                // Navigate based on index
                switch (index) {
                  case 0:
                    // Already on home
                    break;
                  case 1:
                    // Announcements
                    Navigator.pushReplacementNamed(
                        context, AppRouter.announcements);
                    break;
                  case 2:
                    // Rooms
                    Navigator.pushReplacementNamed(
                        context, AppRouter.roomsList);
                    break;
                  case 3:
                    // Settings
                    Navigator.pushReplacementNamed(context, AppRouter.settings);
                    break;
                }
              },
            ),
          ), // End Scaffold
        ); // End RootTabPopScope
      },
    );
  }

  Widget _buildEventHeader(user, event) {
    final userName = user?.fullName ?? 'Invité';
    final eventName = event?.name ?? 'Événement';
    final eventDates = _formatEventDates(event?.startDate, event?.endDate);
    final eventLocation = event?.location ?? 'Lieu à confirmer';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.eventPrimary(context),
            AppColors.eventPrimaryDark(context)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour, $userName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'GESTIONNAIRE DES SALLES',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            eventName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  eventDates,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  eventLocation,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatEventDates(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Dates à confirmer';
    }

    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];

    if (startDate.year != endDate.year) {
      return '${startDate.day} ${months[startDate.month - 1]} ${startDate.year} - ${endDate.day} ${months[endDate.month - 1]} ${endDate.year}';
    } else if (startDate.month != endDate.month) {
      return '${startDate.day} ${months[startDate.month - 1]} - ${endDate.day} ${months[endDate.month - 1]} ${startDate.year}';
    } else {
      return '${startDate.day} - ${endDate.day} ${months[startDate.month - 1]} ${startDate.year}';
    }
  }
}
