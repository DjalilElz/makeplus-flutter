// lib/presentation/screens/participant/session_detail_screen.dart

import 'package:flutter/material.dart';
import '../../../core/constants/theme/app_colors.dart';

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
  bool _showQuestionForm = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _submitQuestion() {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une question'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // TODO: Submit question to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question envoyée avec succès!'),
        backgroundColor: AppColors.success,
      ),
    );

    setState(() {
      _questionController.clear();
      _showQuestionForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLive = widget.session['isLive'] ?? false;
    final bool hasLiveStream = widget.session['hasLiveStream'] ?? false;
    final String youtubeUrl = widget.session['youtubeUrl'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détails de la session',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Speaker Info
                  _buildInfoRow(
                    Icons.person,
                    'Intervenant',
                    widget.session['speaker'],
                  ),
                  const SizedBox(height: 12),

                  // Room
                  _buildInfoRow(
                    Icons.meeting_room,
                    'Salle',
                    widget.session['room'],
                  ),
                  const SizedBox(height: 12),

                  // Time
                  _buildInfoRow(
                    Icons.access_time,
                    'Horaire',
                    widget.session['time'],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                      color: Colors.grey[700],
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
                            const Text(
                              'Poser une question',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _questionController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Écrivez votre question ici...',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showQuestionForm = false;
                                      _questionController.clear();
                                    });
                                  },
                                  child: const Text('Annuler'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _submitQuestion,
                                  child: const Text('Envoyer'),
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
                            disabledBackgroundColor: Colors.grey[300],
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
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
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
