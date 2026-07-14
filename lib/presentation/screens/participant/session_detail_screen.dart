// lib/presentation/screens/participant/session_detail_screen.dart

import 'package:flutter/material.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/session_question_service.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class SessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> session;

  const SessionDetailScreen({
    super.key,
    required this.session,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final TextEditingController _questionController = TextEditingController();
  late final SessionQuestionService _questionService;
  bool _showQuestionForm = false;
  bool _isSubmittingQuestion = false;

  @override
  void initState() {
    super.initState();
    _questionService = SessionQuestionService(ApiClient());
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une question'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final sessionId = widget.session['id'] as String?;
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session introuvable'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmittingQuestion = true);

    try {
      await _questionService.askQuestion(
        sessionId: sessionId,
        questionText: questionText,
      );

      if (!mounted) return;
      setState(() {
        _questionController.clear();
        _showQuestionForm = false;
        _isSubmittingQuestion = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question envoyée avec succès!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      AppLogger.d('❌ ERROR SUBMITTING QUESTION: $e');
      if (!mounted) return;
      setState(() => _isSubmittingQuestion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLive = widget.session['isLive'] ?? false;
    final bool hasLiveStream = widget.session['hasLiveStream'] ?? false;
    final String youtubeUrl = widget.session['youtubeUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Détails de la session'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.session['title'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Speaker Info
                  _buildInfoRow(
                    context,
                    Icons.person,
                    'Intervenant',
                    widget.session['speaker'],
                  ),
                  const SizedBox(height: 12),

                  // Room
                  _buildInfoRow(
                    context,
                    Icons.meeting_room,
                    'Salle',
                    widget.session['room'],
                  ),
                  const SizedBox(height: 12),

                  // Time
                  _buildInfoRow(
                    context,
                    Icons.access_time,
                    'Horaire',
                    widget.session['time'],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.session['description'] +
                        '\n\nCette session explorera en profondeur les concepts '
                            'clés et les applications pratiques dans le domaine. '
                            'Les participants auront l\'opportunité d\'interagir avec '
                            'l\'intervenant et de poser leurs questions en temps réel.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary(context),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Question Form (above buttons)
                  if (_showQuestionForm) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Poser une question',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _questionController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Écrivez votre question ici...',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _isSubmittingQuestion
                                      ? null
                                      : () {
                                          setState(() {
                                            _showQuestionForm = false;
                                            _questionController.clear();
                                          });
                                        },
                                  child: const Text('Annuler'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed:
                                      _isSubmittingQuestion ? null : _submitQuestion,
                                  child: _isSubmittingQuestion
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                                Colors.white),
                                          ),
                                        )
                                      : const Text('Envoyer'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: hasLiveStream || youtubeUrl.isNotEmpty
                              ? () {
                                  Navigator.pushNamed(
                                    context,
                                    '/participant/live-stream',
                                    arguments: widget.session,
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.play_arrow),
                          label:
                              Text(isLive ? 'Regarder en direct' : 'Regarder'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.surfaceContainerHigh(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showQuestionForm = !_showQuestionForm;
                            });
                          },
                          icon: const Icon(Icons.question_answer),
                          label: const Text('Poser une question'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
