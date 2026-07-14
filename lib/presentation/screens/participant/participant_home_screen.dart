// lib/presentation/screens/participant/participant_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

class ParticipantHomeScreen extends StatefulWidget {
  const ParticipantHomeScreen({super.key});

  @override
  State<ParticipantHomeScreen> createState() => _ParticipantHomeScreenState();
}

class _ParticipantHomeScreenState extends State<ParticipantHomeScreen> {
  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/participant/home':
        return 0;
      case '/participant/program':
        return 1;
      case '/participant/profile':
        return 2;
      case '/participant/guide':
        return 3;
      case '/participant/announcements':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RootTabPopScope(
      homeRoute: '/participant/home',
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
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header
              _buildEventHeader(),
              const SizedBox(height: 24),

              // Event Overview
              _buildEventOverview(context),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'eposters',
              onPressed: () {
                // Navigate to E-posters
                Navigator.pushNamed(context, '/participant/eposters');
              },
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.article),
              label: const Text('E-posters'),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'diffusion',
              onPressed: () {
                // Navigate to Diffusion et Q&A
                Navigator.pushNamed(context, '/participant/diffusion');
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.live_tv),
              label: const Text('Diffusion et Q&A'),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _getCurrentIndex(context),
          userRole: 'participant',
          onTap: (index) {
            // Navigate based on index
            switch (index) {
              case 0:
                // Already on Home
                break;
              case 1:
                // Programme
                Navigator.pushReplacementNamed(context, '/participant/program');
                break;
              case 2:
                // Profile (center button)
                Navigator.pushReplacementNamed(context, '/participant/profile');
                break;
              case 3:
                // Guide
                Navigator.pushReplacementNamed(context, '/participant/guide');
                break;
              case 4:
                // Annonces
                Navigator.pushReplacementNamed(context, '/participant/announcements');
                break;
            }
          },
        ),
      ), // End Scaffold
    ); // End RootTabPopScope
  } // End build method

  Widget _buildEventHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = authState.user?.fullName ?? 'Participant';
        final eventName = authState.event?.name ?? 'MakePlus';
        final eventDates = formatEventDates(
            authState.event?.startDate, authState.event?.endDate);
        final eventLocation = authState.event?.location;
        final bannerUrl = authState.event?.bannerUrl;
        final logoUrl = authState.event?.logoUrl;
        final primary = Theme.of(context).colorScheme.primary;
        final primaryDark = Color.lerp(primary, Colors.black, 0.25)!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event banner — sits at the very top of the home screen.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: bannerUrl != null && bannerUrl.isNotEmpty
                    ? Image.network(
                        bannerUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _bannerFallback(primary, primaryDark),
                      )
                    : _bannerFallback(primary, primaryDark),
              ),
            ),
            const SizedBox(height: 16),

            // Event information — name, dates, location.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (logoUrl != null && logoUrl.isNotEmpty) ...[
                        ClipOval(
                          child: Image.network(
                            logoUrl,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      const Text(
                        'Bonjour ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '$userName,',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    eventName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (eventDates != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
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
                  ],
                  if (eventLocation != null && eventLocation.isNotEmpty) ...[
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/event-details');
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
            ),
          ],
        );
      },
    );
  }

  /// Shown in place of the event banner when the event has none set, or the
  /// image fails to load — keeps the same visual footprint instead of
  /// collapsing to nothing.
  Widget _bannerFallback(Color primary, Color primaryDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.event, color: Colors.white38, size: 48),
      ),
    );
  }

  String? formatEventDates(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return null;
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
    } else if (startDate.month == endDate.month) {
      return '${startDate.day}-${endDate.day} ${months[startDate.month - 1]} ${startDate.year}';
    } else {
      return '${startDate.day} ${months[startDate.month - 1]} - ${endDate.day} ${months[endDate.month - 1]} ${startDate.year}';
    }
  }

  Widget _buildEventOverview(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final description = authState.event?.description?.trim();
        if (description == null || description.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sur l\'événement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
