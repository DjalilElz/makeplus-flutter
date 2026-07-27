// lib/presentation/screens/participant/live_stream_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/session_question_service.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class LiveStreamScreen extends StatefulWidget {
  final Map<String, dynamic> session;

  const LiveStreamScreen({super.key, required this.session});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  late YoutubePlayerController _youtubeController;
  late SessionQuestionService _questionService;
  late String _sessionId;
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isFullscreen = false;
  bool _showQuestionBoxInFullscreen = false;
  bool _isLoadingQuestions = true;
  bool _isSendingQuestion = false;

  // User questions loaded from API
  List<Map<String, dynamic>> _userQuestions = [];

  // The API never returns who asked a question (SessionQuestion.participant is
  // write_only — anonymous by design). The only way to label a question "Vous"
  // is to remember, client-side, which ones this session submitted.
  final Set<String> _myQuestionIds = {};

  @override
  void initState() {
    super.initState();

    _questionService = SessionQuestionService(ApiClient());
    _sessionId = widget.session['id'] as String;

    AppLogger.d('🎬 LIVE STREAM SCREEN INITIALIZED');
    AppLogger.d('📺 Session ID: $_sessionId');
    AppLogger.d('📺 Session Data: ${widget.session}');

    // Extract video ID from URL
    final videoUrl = widget.session['youtubeUrl'] ??
        'https://www.youtube.com/watch?v=T4Oh0eJLRQo';
    final videoId = YoutubePlayer.convertUrlToId(videoUrl) ?? 'T4Oh0eJLRQo';

    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
      ),
    );

    _youtubeController.addListener(() {
      if (_youtubeController.value.isFullScreen != _isFullscreen) {
        setState(() {
          _isFullscreen = _youtubeController.value.isFullScreen;
        });
      }
    });

    // Load questions from API
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      AppLogger.d('📡 LOADING QUESTIONS for session: $_sessionId');

      final questions = await _questionService.getQuestions(_sessionId);
      AppLogger.d('✅ LOADED ${questions.length} questions');

      setState(() {
        _userQuestions = questions.map<Map<String, dynamic>>((q) {
          return {
            'id': q.id,
            'question': q.questionText,
            'time': _formatTime(q.askedAt.toIso8601String()),
            'is_answered': q.isAnswered,
            'is_mine': _myQuestionIds.contains(q.id),
          };
        }).toList();
        _isLoadingQuestions = false;
      });
    } catch (e) {
      AppLogger.d('❌ ERROR LOADING QUESTIONS: $e');
      setState(() {
        _isLoadingQuestions = false;
      });
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';

    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _chatScrollController.dispose();
    _youtubeController.dispose();
    // Reset orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _sendMessage() async {
    if (_questionController.text.trim().isEmpty) return;
    if (_isSendingQuestion) return; // Prevent double submission

    final questionText = _questionController.text.trim();
    _questionController.clear();

    setState(() {
      _isSendingQuestion = true;
    });

    try {
      AppLogger.d('📤 SENDING QUESTION: $questionText');
      AppLogger.d('📤 SESSION ID: $_sessionId');

      final question = await _questionService.askQuestion(
        sessionId: _sessionId,
        questionText: questionText,
      );

      AppLogger.d('✅ QUESTION SENT SUCCESSFULLY');

      _myQuestionIds.add(question.id);

      // Add question to local list immediately
      setState(() {
        _userQuestions.insert(0, {
          'id': question.id,
          'question': questionText,
          'time': _formatTime(question.askedAt.toIso8601String()),
          'is_answered': false,
          'is_mine': true,
        });
        _isSendingQuestion = false;
      });

      // Auto scroll to top (since we insert at 0)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Question envoyée ! Elle sera posée à l\'oral pendant la session.',
          ),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      AppLogger.d('❌ ERROR SENDING QUESTION: $e');

      if (!mounted) return;
      setState(() {
        _isSendingQuestion = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _youtubeController,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.eventPrimary(context),
        onReady: () {
          AppLogger.d('YouTube Player is ready');
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor:
              _isFullscreen ? Colors.black : AppColors.background(context),
          appBar: _isFullscreen
              ? null
              : AppBar(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    widget.session['title'],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
          body: _isFullscreen
              ? _buildFullscreenView(player)
              : _buildNormalView(player),
          // Anchor the message input to the scaffold so keyboard insets
          // don't cause the scrollable content to overflow.
          bottomNavigationBar:
              _isFullscreen ? null : SafeArea(child: _buildMessageInput()),
        );
      },
    );
  }

  Widget _buildNormalView(Widget player) {
    return Column(
      children: [
        // Video Player
        Container(color: Colors.black, child: player),

        // Content below video
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              color: AppColors.background(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Session Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground(context),
                      border: Border(
                        bottom:
                            BorderSide(color: AppColors.borderColor(context)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.circle,
                                    color: Colors.white,
                                    size: 8,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'EN DIRECT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_userQuestions.length} questions posées',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.session['speaker'],
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User's Questions Section
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 200,
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: _buildQuestionsSection(),
                  ),

                  // message input moved to Scaffold.bottomNavigationBar
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenView(Widget player) {
    return Stack(
      children: [
        // Video Player (full screen)
        Center(child: player),

        // Question Button
        if (!_showQuestionBoxInFullscreen)
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton(
              heroTag: 'question',
              backgroundColor: AppColors.eventPrimary(context).withValues(alpha: 0.9),
              onPressed: () {
                setState(() {
                  _showQuestionBoxInFullscreen = true;
                });
              },
              child: const Icon(Icons.question_answer),
            ),
          ),

        // Question Input Box (small overlay)
        if (_showQuestionBoxInFullscreen)
          Positioned(
            right: 16,
            bottom: 80,
            left: 16,
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.chat, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Mes Questions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _showQuestionBoxInFullscreen = false;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildQuestionsListFullscreen()),
                  _buildFullscreenMessageInput(),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionsSection() {
    return Container(
      color: AppColors.background(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBackground(context),
            child: Row(
              children: [
                Icon(Icons.question_answer,
                    color: AppColors.eventPrimary(context), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mes Questions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const Spacer(),
                if (_isLoadingQuestions)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingQuestions
                ? const Center(child: CircularProgressIndicator())
                : _userQuestions.isEmpty
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
                              'Aucune question posée',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _chatScrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _userQuestions.length,
                        itemBuilder: (context, index) {
                          final question = _userQuestions[index];
                          final isAnswered = question['is_answered'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_circle,
                                        size: 20,
                                        color: AppColors.eventPrimary(context),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        (question['is_mine'] as bool? ?? false)
                                            ? 'Vous'
                                            : 'Participant anonyme',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.textPrimary(context),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isAnswered)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'RÉPONDU',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        question['time'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    question['question'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                  if (isAnswered) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.record_voice_over,
                                          size: 13,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Traitée à l\'oral par l\'intervenant',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.textSecondary(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsListFullscreen() {
    if (_isLoadingQuestions) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return _userQuestions.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.question_answer_outlined,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucune question posée',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _userQuestions.length,
            itemBuilder: (context, index) {
              final question = _userQuestions[index];
              final isAnswered = question['is_answered'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: isAnswered
                      ? Border.all(
                          color: AppColors.success.withValues(alpha: 0.5), width: 1.5)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_circle,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (question['is_mine'] as bool? ?? false)
                              ? 'Vous'
                              : 'Participant anonyme',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        if (isAnswered)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'RÉPONDU',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          question['time'] ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      question['question'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                    if (isAnswered) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.record_voice_over,
                            size: 12,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Traitée à l\'oral par l\'intervenant',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        border: Border(top: BorderSide(color: AppColors.borderColor(context))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: 'Poser une question...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              color: AppColors.eventPrimary(context),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.eventPrimary(context).withValues(alpha: 0.1),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5)),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _questionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Poser une question...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.eventPrimary(context).withValues(alpha: 0.8),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
