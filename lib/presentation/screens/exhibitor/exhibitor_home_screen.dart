// lib/presentation/screens/exhibitor/exhibitor_home_screen.dart

import 'package:flutter/material.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

class ExhibitorHomeScreen extends StatefulWidget {
  const ExhibitorHomeScreen({super.key});

  @override
  State<ExhibitorHomeScreen> createState() => _ExhibitorHomeScreenState();
}

class _ExhibitorHomeScreenState extends State<ExhibitorHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return RootTabPopScope(
      homeRoute: '/exhibitor/home',
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header
              _buildEventHeader(),
              const SizedBox(height: 24),

              // Quick Stats
              _buildQuickStats(),
              const SizedBox(height: 24),

              // Event Info
              _buildEventInfo(),
              const SizedBox(height: 24),

              // Committee Section
              _buildCommitteeSection(),
              const SizedBox(height: 24),

              // Featured Image
              _buildFeaturedImage(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/exhibitor/scanner');
          },
          backgroundColor: AppColors.eventPrimary(context),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scanner'),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          userRole: 'exhibitor',
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ), // End Scaffold
    ); // End RootTabPopScope
  }

  Widget _buildEventHeader() {
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
              const Text(
                'Arslene,',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Rôle: Exposant',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'MakePlus 2025',
            style: TextStyle(
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
              const Text(
                '12-14 Novembre 2025',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
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
              const Expanded(
                child: Text(
                  'Centre des Congrès, Alger',
                  style: TextStyle(
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

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '48',
            'Visiteurs\nScannés',
            Icons.people,
            AppColors.eventPrimary(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '15',
            'Nouveaux\nContacts',
            Icons.contact_page,
            AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo() {
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
            '• Réseaux & Technologies numériques\n'
            '• Robotique',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitteeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.eventPrimary(context).withValues(alpha: 0.1),
            AppColors.eventPrimaryLight(context).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mot des présidents / comité',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chers exposants, nous vous remercions pour '
            'votre participation à MakePlus 2025. Vous êtes '
            'les piliers de l\'événement avenir et riche. '
            'Nous espérons que vos échanges seront '
            'fructueux et porteurs de collaborations durables.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Voir +'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('En savoir +'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedImage() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh(context),
            ),
            child: Center(
              child: Icon(
                Icons.image,
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
                  'Bienvenue à MakePlus 2025',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Une édition pleine d\'innovations, aux '
                  'côtés de chercheurs, professeurs et '
                  'professionnels.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                    height: 1.5,
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
