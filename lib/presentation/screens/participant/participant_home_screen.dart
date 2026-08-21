// lib/presentation/screens/participant/participant_home_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
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
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'eposters',
          onPressed: () {
            // Navigate to E-posters
            Navigator.pushNamed(context, '/participant/eposters');
          },
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.article),
          label: const Text('E-posters'),
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
        final eventName = authState.event?.name ?? 'Synapt';
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
            // Fixed 2:1 aspect ratio (not a fixed height) so every device
            // crops/frames the banner the same way — see the CLAUDE.md note
            // on recommended source dimensions for designers.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 2 / 1,
                child: bannerUrl != null && bannerUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: bannerUrl,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 150),
                        placeholder: (context, url) =>
                            _bannerFallback(primary, primaryDark),
                        errorWidget: (context, url, error) =>
                            _bannerFallback(primary, primaryDark),
                      )
                    : _bannerFallback(primary, primaryDark),
              ),
            ),
            const SizedBox(height: 16),

            // Event information — name, dates, location.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          child: CachedNetworkImage(
                            imageUrl: logoUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 150),
                            errorWidget: (context, url, error) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      const Text(
                        'Bonjour ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '$userName,',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    eventName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (eventDates != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            eventDates,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (eventLocation != null && eventLocation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            eventLocation,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
