// lib/presentation/screens/organizer_room_manager/questions_screen.dart

import 'package:flutter/material.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/models/session_question_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/page_cache_service.dart';
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

  // Question currently being marked/unmarked, so only that card shows a
  // spinner instead of blocking the whole list.
  String? _togglingId;

  String get _cacheKey => 'questions_${widget.sessionId}';

  @override
  void initState() {
    super.initState();
    _questionService = SessionQuestionService(ApiClient());
    _loadFromCacheThenRefresh();
  }

  void _loadFromCacheThenRefresh() {
    final cached =
        PageCacheService.instance.get<List<SessionQuestionModel>>(_cacheKey);
    if (cached != null) _questions = cached;
    _loadQuestions(showSpinner: cached == null);
  }

  Future<void> _loadQuestions({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final questions = await _questionService.getQuestions(widget.sessionId);
      if (!mounted) return;
      PageCacheService.instance.set(_cacheKey, questions);
      setState(() {
        _questions = questions;
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      if (showSpinner) {
        setState(() {
          _error = 'Impossible de charger les questions.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAnswered(SessionQuestionModel question) async {
    setState(() => _togglingId = question.id);

    try {
      final updated = await _questionService.toggleAnswered(question.id);
      if (!mounted) return;
      final updatedList =
          _questions?.map((q) => q.id == question.id ? updated : q).toList();
      if (updatedList != null) {
        PageCacheService.instance.set(_cacheKey, updatedList);
      }
      setState(() {
        _questions = updatedList;
        _togglingId = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _togglingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de mettre à jour la question.'),
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
      onRefresh: () => _loadQuestions(showSpinner: false),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        itemBuilder: (context, index) =>
            _buildQuestionCard(context, sorted[index]),
      ),
    );
  }

  Widget _buildQuestionCard(
      BuildContext context, SessionQuestionModel question) {
    final isToggling = _togglingId == question.id;

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
                Icon(Icons.person_off_outlined,
                    size: 16, color: AppColors.textSecondary(context)),
                const SizedBox(width: 6),
                Text(
                  'Question anonyme',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary(context)),
                ),
                const Spacer(),
                Text(
                  question.formattedAskedAt,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textHint(context)),
                ),
                const SizedBox(width: 8),
                if (question.isAnswered)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 13, color: AppColors.success),
                        SizedBox(width: 4),
                        Text('Répondu',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('En attente',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600)),
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
                style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.textPrimary(context)),
              ),
            ),
            if (question.isAnswered &&
                (question.answeredByName ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Marquée comme répondue par ${question.answeredByName}',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary(context)),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: question.isAnswered
                  ? OutlinedButton.icon(
                      onPressed:
                          isToggling ? null : () => _toggleAnswered(question),
                      icon: isToggling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.replay, size: 18),
                      label: const Text('Marquer comme non répondue'),
                    )
                  : ElevatedButton.icon(
                      onPressed:
                          isToggling ? null : () => _toggleAnswered(question),
                      icon: isToggling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('Marquer comme répondue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.eventPrimary(context),
                        foregroundColor: Colors.white,
                      ),
                    ),
            ),
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
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: AppColors.textHint(context)),
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
