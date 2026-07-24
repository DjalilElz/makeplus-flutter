// lib/presentation/screens/organizer_room_manager/questions_screen.dart

import 'package:flutter/material.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/models/session_question_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/session_question_service.dart';

/// Q&A for a single session -- reached by drilling into a session from the
/// room manager's rooms/sessions list, not a root tab (so it's a normal
/// pushed subpage: back arrow, no bottom nav bar).
///
/// Anonymous by design: the backend never returns who asked a question, so
/// there is no asker name/avatar to show here, only the question text.
class QuestionsScreen extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;

  const QuestionsScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  late final SessionQuestionService _questionService;

  List<SessionQuestionModel>? _questions;
  bool _isLoading = false;
  String? _error;

  // Tracks which question is currently being answered (its inline reply
  // field is expanded) and whether a submit is in flight for it.
  String? _replyingToId;
  final Map<String, TextEditingController> _replyControllers = {};
  bool _isSubmittingAnswer = false;

  @override
  void initState() {
    super.initState();
    _questionService = SessionQuestionService(ApiClient());
    _loadQuestions();
  }

  @override
  void dispose() {
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final questions = await _questionService.getQuestions(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les questions.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer(SessionQuestionModel question) async {
    final controller = _replyControllers[question.id];
    final answerText = controller?.text.trim() ?? '';
    if (answerText.isEmpty) return;

    setState(() => _isSubmittingAnswer = true);

    try {
      final updated = await _questionService.answerQuestion(
        questionId: question.id,
        answerText: answerText,
      );
      if (!mounted) return;
      setState(() {
        _questions = _questions
            ?.map((q) => q.id == question.id ? updated : q)
            .toList();
        _replyingToId = null;
        _isSubmittingAnswer = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmittingAnswer = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'envoyer la réponse.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionTitle),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildMessage(
        context,
        icon: Icons.error_outline,
        title: 'Erreur',
        message: _error!,
        action: TextButton(
          onPressed: _loadQuestions,
          child: const Text('Réessayer'),
        ),
      );
    }
    final questions = _questions ?? [];
    if (questions.isEmpty) {
      return _buildMessage(
        context,
        icon: Icons.question_answer_outlined,
        title: 'Aucune question pour le moment',
        message: 'Les questions posées pendant cette session apparaîtront ici.',
      );
    }

    // Most recent first.
    final sorted = List<SessionQuestionModel>.from(questions)
      ..sort((a, b) => b.askedAt.compareTo(a.askedAt));

    return RefreshIndicator(
      onRefresh: _loadQuestions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        itemBuilder: (context, index) => _buildQuestionCard(context, sorted[index]),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, SessionQuestionModel question) {
    final isReplying = _replyingToId == question.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: question.isAnswered
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.borderColor(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_off_outlined, size: 16, color: AppColors.textSecondary(context)),
                const SizedBox(width: 6),
                Text(
                  'Question anonyme',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                ),
                const Spacer(),
                Text(
                  question.formattedAskedAt,
                  style: TextStyle(fontSize: 12, color: AppColors.textHint(context)),
                ),
                const SizedBox(width: 8),
                if (question.isAnswered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 13, color: AppColors.success),
                        SizedBox(width: 4),
                        Text('Répondu', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('En attente', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question.questionText,
                style: TextStyle(fontSize: 15, height: 1.4, color: AppColors.textPrimary(context)),
              ),
            ),

            if (question.isAnswered) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((question.answeredByName ?? '').isNotEmpty)
                      Text(
                        'Réponse — ${question.answeredByName}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
                      ),
                    const SizedBox(height: 4),
                    Text(question.answerText ?? '', style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context))),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              if (isReplying) ...[
                TextField(
                  controller: _replyControllers.putIfAbsent(question.id, () => TextEditingController()),
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Écrire une réponse...',
                    filled: true,
                    fillColor: AppColors.surfaceContainer(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmittingAnswer ? null : () => setState(() => _replyingToId = null),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmittingAnswer ? null : () => _submitAnswer(question),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.eventPrimary(context),
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmittingAnswer
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Envoyer'),
                      ),
                    ),
                  ],
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _replyingToId = question.id),
                    icon: const Icon(Icons.reply, size: 18),
                    label: const Text('Répondre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.eventPrimary(context),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint(context)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textHint(context)),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
