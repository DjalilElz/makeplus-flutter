// lib/presentation/screens/exposant/exposant_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

class ExposantHomeScreen extends StatefulWidget {
  const ExposantHomeScreen({super.key});

  @override
  State<ExposantHomeScreen> createState() => _ExposantHomeScreenState();
}

class _ExposantHomeScreenState extends State<ExposantHomeScreen> {
  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/exposant/home':
        return 0;
      case '/exposant/guide':
        return 1;
      case '/exposant/scanner':
        return 2;
      case '/exposant/stats':
        return 3;
      case '/exposant/announcements':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RootTabPopScope(
      homeRoute: '/exposant/home',
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
              const SizedBox(height: 24),

              // President's Message
              _buildPresidentMessage(context),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _getCurrentIndex(context),
          userRole: 'exposant',
          onTap: (index) {
            // Navigate based on index
            switch (index) {
              case 0:
                // Already on Home
                break;
              case 1:
                // Guide
                Navigator.pushReplacementNamed(context, '/exposant/guide');
                break;
              case 2:
                // QR Scanner (center button)
                Navigator.pushNamed(context, '/exposant/scanner');
                break;
              case 3:
                // Stats
                Navigator.pushReplacementNamed(context, '/exposant/stats');
                break;
              case 4:
                // Annonces
                Navigator.pushReplacementNamed(
                    context, '/exposant/announcements');
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
        final userName = authState.user?.fullName ?? 'Exposant';
        final eventName = authState.event?.name ?? 'MakePlus 2025';
        final eventLocation =
            authState.event?.location ?? 'Centre de Conférences';
        final eventDates = formatEventDates(
            authState.event?.startDate, authState.event?.endDate);

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
              Row(
                children: [
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
                      overflow: TextOverflow.ellipsis,
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
                  Flexible(
                    child: Text(
                      eventLocation,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
        );
      },
    );
  }

  String formatEventDates(DateTime? startDate, DateTime? endDate) {
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

  Widget _buildEventOverview(BuildContext context) {
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
            'Thématiques principales:\n'
            '• Intelligence Artificielle & Data Science\n'
            '• Santé & Innovation\n'
            '• Technologies médicales\n'
            '• Énergie renouvelable & écologie\n'
            '• Réseaux & communications',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Faciliter les connexions, élever le networking.\n'
            'Présence de centres de recherche innovants.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresidentMessage(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // President Image (optional)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                size: 80,
                color: AppColors.textHint(context),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mot du Président',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chers participants,\n\n'
                  'C\'est avec un immense plaisir que je vous accueille à MakePlus 2025. '
                  'Cette édition promet d\'être une plateforme exceptionnelle pour '
                  'l\'innovation, les échanges et la collaboration.\n\n'
                  'Nous sommes ravis de vous accompagner dans cette aventure scientifique '
                  'et technologique qui façonnera l\'avenir.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                    height: 1.6,
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
