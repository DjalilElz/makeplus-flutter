// lib/presentation/screens/organizer_room_manager/questions_screen.dart

import 'package:flutter/material.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../routes/app_router.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
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
      case '/organizer-room-manager/questions':
        return 4;
      default:
        return 4;
    }
  }

  // Mock data for questions - only for the assigned room (Salle 3)
  final List<Map<String, dynamic>> _questions = [
    {
      'id': 1,
      'question': 'Quelle est la durée de la pause déjeuner ?',
      'asker': 'Mohamed ALAMI',
      'askerType': 'Participant',
      'room': 'Salle 3',
      'timestamp': '10:30',
      'isAnswered': false,
    },
    {
      'id': 2,
      'question': 'Y a-t-il une session de networking après la conférence ?',
      'asker': 'Sarah BENALI',
      'askerType': 'Exposant',
      'room': 'Salle 3',
      'timestamp': '11:15',
      'isAnswered': false,
    },
    {
      'id': 3,
      'question':
          'Peut-on enregistrer la présentation pour la revoir plus tard ?',
      'asker': 'Karim ETTAKI',
      'askerType': 'Participant',
      'room': 'Salle 3',
      'timestamp': '11:45',
      'isAnswered': true,
    },
    {
      'id': 4,
      'question': 'Où se trouve la salle de prière la plus proche ?',
      'asker': 'Amina BENDJEBBAR',
      'askerType': 'Participant',
      'room': 'Salle 3',
      'timestamp': '12:00',
      'isAnswered': false,
    },
    {
      'id': 5,
      'question':
          'Le matériel de démonstration est-il disponible pour les exposants ?',
      'asker': 'Rachid MANSOURI',
      'askerType': 'Exposant',
      'room': 'Salle 3',
      'timestamp': '14:20',
      'isAnswered': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Sort questions by timestamp (most recent first)
    final sortedQuestions = List<Map<String, dynamic>>.from(_questions)
      ..sort((a, b) {
        final timeA = a['timestamp'] as String;
        final timeB = b['timestamp'] as String;
        return timeB.compareTo(timeA); // Descending order
      });

    return RootTabPopScope(
      homeRoute: AppRouter.organizerRoomManagerHome,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(
                    context, AppRouter.organizerRoomManagerHome);
              }
            },
          ),
          title: const Text('Questions - Salle 3'),
        ),
        body: Column(
          children: [
            // Room Info Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.primary.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.meeting_room,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salle 3 - Conférences',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_questions.length} questions',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Questions List
            Expanded(
              child: _questions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.question_answer_outlined,
                            size: 64,
                            color: AppColors.textHint(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune question pour le moment',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: sortedQuestions.length,
                      itemBuilder: (context, index) {
                        final question = sortedQuestions[index];
                        return _buildQuestionCard(question);
                      },
                    ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _getCurrentIndex(context),
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
                Navigator.pushReplacementNamed(context, AppRouter.roomsList);
                break;
              case 3:
                // Already on Questions/Settings
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final bool isAnswered = question['isAnswered'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAnswered
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.borderColor(context),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with asker info and status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: question['askerType'] == 'Exposant'
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.2),
                  radius: 20,
                  child: Text(
                    question['asker'][0],
                    style: TextStyle(
                      color: question['askerType'] == 'Exposant'
                          ? AppColors.accent
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question['asker'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: question['askerType'] == 'Exposant'
                                  ? AppColors.accent.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              question['askerType'],
                              style: TextStyle(
                                fontSize: 11,
                                color: question['askerType'] == 'Exposant'
                                    ? AppColors.accent
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.textSecondary(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            question['timestamp'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isAnswered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Répondu',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Question text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question['question'],
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement show question detail/answer logic
                  _showQuestionDetailDialog(question);
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Afficher'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionDetailDialog(Map<String, dynamic> question) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Détails de la question',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Posée par: ${question['asker']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type: ${question['askerType']}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Heure: ${question['timestamp']}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Question:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question['question'],
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement answer logic
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Répondre'),
            ),
          ],
        );
      },
    );
  }
}
