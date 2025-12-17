// lib/presentation/screens/participant/live_stream_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';

class LiveStreamScreen extends StatefulWidget {
  final Map<String, dynamic> session;

  const LiveStreamScreen({super.key, required this.session});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  late YoutubePlayerController _youtubeController;
  late ApiClient _apiClient;
  late String _sessionId;
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isFullscreen = false;
  bool _showQuestionBoxInFullscreen = false;
  bool _isLoadingQuestions = true;
  bool _isSendingQuestion = false;

  // User questions loaded from API
  List<Map<String, dynamic>> _userQuestions = [];

  @override
  void initState() {
    super.initState();

    // Initialize API client and session ID
    _apiClient = ApiClient();
    _sessionId = widget.session['id'] as String;

    print('🎬 LIVE STREAM SCREEN INITIALIZED');
    print('📺 Session ID: $_sessionId');
    print('📺 Session Data: ${widget.session}');

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
      print('📡 LOADING QUESTIONS for session: $_sessionId');

      final response = await _apiClient.get(
        '/session-questions/',
        queryParameters: {'session': _sessionId},
      );

      final questionsList = response.data['results'] as List? ?? [];
      print('✅ LOADED ${questionsList.length} questions');

      setState(() {
        _userQuestions = questionsList.map<Map<String, dynamic>>((q) {
          return {
            'id': q['id'],
            'question': q['question_text'] ?? '',
            'time': _formatTime(q['asked_at']),
            'is_answered': q['is_answered'] ?? false,
            'answer': q['answer_text'],
            'participant_name': q['participant_name'] ?? 'Vous',
          };
        }).toList();
        _isLoadingQuestions = false;
      });
    } catch (e) {
      print('❌ ERROR LOADING QUESTIONS: $e');
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
      print('📤 SENDING QUESTION: $questionText');
      print('📤 SESSION ID: $_sessionId');

      // Backend auto-extracts participant from JWT token
      // Only send session and question_text
      final requestData = {
        'session': _sessionId,
        'question_text': questionText,
      };

      print('📤 REQUEST DATA: $requestData');

      final response = await _apiClient.post(
        '/session-questions/',
        data: requestData,
      );

      print('✅ QUESTION SENT SUCCESSFULLY');
      print('✅ RESPONSE: ${response.data}');

      // Add question to local list immediately
      setState(() {
        _userQuestions.insert(0, {
          'id': response.data['id'],
          'question': questionText,
          'time': _formatTime(response.data['asked_at']),
          'is_answered': false,
          'answer': null,
          'participant_name': 'Vous',
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question envoyée avec succès!'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      print('❌ ERROR SENDING QUESTION: $e');

      // Try to extract more error details
      String errorMessage = 'Erreur lors de l\'envoi';
      if (e.toString().contains('DioException')) {
        try {
          final dioError = e as dynamic;
          if (dioError.response?.data != null) {
            print('❌ BACKEND ERROR RESPONSE: ${dioError.response.data}');
            // Try to get error message from backend
            if (dioError.response.data is Map) {
              final data = dioError.response.data as Map;
              if (data.containsKey('detail')) {
                errorMessage = data['detail'].toString();
              } else if (data.containsKey('error')) {
                errorMessage = data['error'].toString();
              } else if (data.containsKey('message')) {
                errorMessage = data['message'].toString();
              }
            }
          }
        } catch (_) {
          // Ignore parsing errors
        }
      }

      setState(() {
        _isSendingQuestion = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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
        progressIndicatorColor: AppColors.primary,
        onReady: () {
          print('YouTube Player is ready');
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: _isFullscreen ? Colors.black : Colors.white,
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
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Session Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.session['speaker'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
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
              backgroundColor: AppColors.primary.withOpacity(0.9),
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
                color: Colors.black.withOpacity(0.85),
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
      color: Colors.grey[50],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.question_answer,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Mes Questions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune question posée',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
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
                          final answer = question['answer'] as String?;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.account_circle,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        question['participant_name'] ?? 'Vous',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
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
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    question['question'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  // Show answer if available
                                  if (isAnswered &&
                                      answer != null &&
                                      answer.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.record_voice_over,
                                                size: 14,
                                                color: AppColors.primary,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Réponse:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            answer,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
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
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucune question posée',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.5),
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
              final answer = question['answer'] as String?;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: isAnswered
                      ? Border.all(
                          color: AppColors.success.withOpacity(0.5), width: 1.5)
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
                          question['participant_name'] ?? 'Vous',
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
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      question['question'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                    // Show answer if available
                    if (isAnswered && answer != null && answer.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.record_voice_over,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Réponse:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              answer,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: 'Poser une question...',
                  filled: true,
                  fillColor: Colors.grey[100],
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
              color: AppColors.primary,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
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
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _questionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Poser une question...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
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
                backgroundColor: AppColors.primary.withOpacity(0.8),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
