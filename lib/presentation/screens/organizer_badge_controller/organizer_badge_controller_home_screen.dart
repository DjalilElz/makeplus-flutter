// lib/presentation/screens/organizer_badge_controller/organizer_badge_controller_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../../routes/app_router.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

class OrganizerBadgeControllerHomeScreen extends StatefulWidget {
  const OrganizerBadgeControllerHomeScreen({super.key});

  @override
  State<OrganizerBadgeControllerHomeScreen> createState() =>
      _OrganizerBadgeControllerHomeScreenState();
}

class _OrganizerBadgeControllerHomeScreenState
    extends State<OrganizerBadgeControllerHomeScreen> {
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
          homeRoute: AppRouter.organizerBadgeControllerHome,
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.settings);
                  },
                ),
              ],
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
              userRole: 'organizer_badge_controller',
              onTap: (index) {
                // Navigate based on index
                switch (index) {
                  case 0:
                    // Already on home
                    break;
                  case 1:
                    // Announcements (view only)
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.badgeControllerAnnouncements,
                    );
                    break;
                  case 2:
                    // Scanner (middle button)
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.badgeScanner,
                    );
                    break;
                  case 3:
                    // Program
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.badgeControllerProgram,
                    );
                    break;
                  case 4:
                    // Stats
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.badgeControllerStats,
                    );
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
          const Text(
            'CONTRÔLEUR DE BADGE',
            style: TextStyle(
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.eventDetails);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text(
                'Voir les details',
                style: TextStyle(fontSize: 14),
              ),
            ),
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
