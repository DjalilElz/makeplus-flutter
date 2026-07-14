// lib/presentation/screens/participant/eposters_screen.dart

import 'package:flutter/material.dart';
import '../../../core/constants/theme/app_colors.dart';

class EpostersScreen extends StatefulWidget {
  const EpostersScreen({super.key});

  @override
  State<EpostersScreen> createState() => _EpostersScreenState();
}

class _EpostersScreenState extends State<EpostersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock data for e-posters
  final List<Map<String, dynamic>> _eposters = [
    {
      'id': 1,
      'title': 'Intelligence Artificielle dans le Diagnostic Médical',
      'authors': 'Dr. Ahmed Benali, Dr. Sarah Mansouri',
      'category': 'IA & Santé',
      'imageUrl': null,
    },
    {
      'id': 2,
      'title': 'Énergie Solaire: Solutions Innovantes',
      'authors': 'Eng. Karim Alaoui, Prof. Fatima Zahra',
      'category': 'Énergie Renouvelable',
      'imageUrl': null,
    },
    {
      'id': 3,
      'title': 'Blockchain et Sécurité des Données',
      'authors': 'Dr. Youssef Idrissi',
      'category': 'Technologie',
      'imageUrl': null,
    },
    {
      'id': 4,
      'title': 'Robotique Médicale: Avancées Récentes',
      'authors': 'Prof. Omar Senhaji, Dr. Leila Tazi',
      'category': 'Robotique',
      'imageUrl': null,
    },
    {
      'id': 5,
      'title': 'IoT dans l\'Agriculture Intelligente',
      'authors': 'Eng. Nadia Berrada',
      'category': 'IoT',
      'imageUrl': null,
    },
    {
      'id': 6,
      'title': 'Machine Learning pour la Prédiction Climatique',
      'authors': 'Dr. Hassan Mouttaki, Dr. Amina Alami',
      'category': 'Data Science',
      'imageUrl': null,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredEposters() {
    if (_searchQuery.isEmpty) {
      return _eposters;
    }
    return _eposters.where((poster) {
      final title = poster['title'].toString().toLowerCase();
      final authors = poster['authors'].toString().toLowerCase();
      final category = poster['category'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) ||
          authors.contains(query) ||
          category.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEposters = _getFilteredEposters();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('E-Posters'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBackground(context),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un poster...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // E-Posters List
          Expanded(
            child: filteredEposters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: AppColors.textHint(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun poster trouvé',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEposters.length,
                    itemBuilder: (context, index) {
                      final poster = filteredEposters[index];
                      return _buildEposterCard(poster);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEposterCard(Map<String, dynamic> poster) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Image Placeholder
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.7),
                  AppColors.accent.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.article,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      poster['category'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Poster Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  poster['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),

                // Authors
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        poster['authors'],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Consulter Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Open PDF viewer or detailed view
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Consultation de: ${poster['title']}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Consulter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
