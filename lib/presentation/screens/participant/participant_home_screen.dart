// lib/presentation/screens/participant/participant_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';

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
    return Scaffold(
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
            _buildEventOverview(),
            const SizedBox(height: 24),

            // President's Message
            _buildPresidentMessage(),
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
              Navigator.pushNamed(context, '/participant/profile');
              break;
            case 3:
              // Guide
              Navigator.pushReplacementNamed(context, '/participant/guide');
              break;
            case 4:
              // Annonces
              Navigator.pushReplacementNamed(
                  context, '/participant/announcements');
              break;
          }
        },
      ),
    );
  }

  Widget _buildEventHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = authState.user?.fullName ?? 'Participant';
        final eventName = authState.event?.name ?? 'MakePlus 2025';
        final eventDates = _formatEventDates(
            authState.event?.startDate, authState.event?.endDate);
        final eventLocation =
            authState.event?.location ?? 'Centre des Congrès, Alger';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
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
      },
    );
  }

  String _formatEventDates(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return '12-14 Novembre 2025';
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

  Widget _buildEventOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sur l\'événement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Faciliter les connexions, élever le networking.\n'
            'Présence de centres de recherche innovants.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresidentMessage() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // President Image (optional)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mot du Président',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bienvenue à tous!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
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
