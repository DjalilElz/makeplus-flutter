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

  Future<void> _submitQuestion(
    BuildContext dialogContext,
    StateSetter setDialogState,
    void Function(bool) setSubmitting,
  ) async {
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

    setDialogState(() => setSubmitting(true));

    try {
      await _questionService.askQuestion(
        sessionId: sessionId,
        questionText: questionText,
      );

      _questionController.clear();

      // The dialog may already be gone by the time the request resolves
      // (barrier tap, back gesture, or the keyboard-dismiss tap landing on
      // the barrier) -- that must never swallow the confirmation. Closing
      // the dialog and showing the success message are independent: only
      // the former needs the dialog to still be there.
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Question envoyée ! Elle sera posée à l\'oral pendant la session.',
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
    } catch (e) {
      AppLogger.d('❌ ERROR SUBMITTING QUESTION: $e');
      if (dialogContext.mounted) {
        setDialogState(() => setSubmitting(false));
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAskQuestionDialog() {
    bool isSubmitting = false;
    _questionController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              // Block the barrier tap / back gesture while the request is
              // in flight so the loading state can't be interrupted --
              // the response handler needs the dialog to still be there.
              canPop: !isSubmitting,
              child: AlertDialog(
                title: const Text('Poser une question'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre question sera posée à l\'oral par l\'intervenant '
                      'pendant la session.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _questionController,
                      autofocus: true,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Écrivez votre question ici...',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            _questionController.clear();
                            Navigator.pop(dialogContext);
                          },
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () => _submitQuestion(
                              dialogContext,
                              setDialogState,
                              (value) => isSubmitting = value,
                            ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Envoyer'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                            backgroundColor: AppColors.eventPrimary(context),
                            disabledBackgroundColor:
                                AppColors.surfaceContainerHigh(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showAskQuestionDialog,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 8,
                            ),
                            foregroundColor: AppColors.eventPrimary(context),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.question_answer, size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Poser une question',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
            color: AppColors.eventPrimary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.eventPrimary(context),
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
