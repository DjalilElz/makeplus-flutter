/// Session Question Model
/// Q&A system for sessions
class SessionQuestionModel {
  final String id;
  final String sessionId;
  final String participantId;
  final String questionText;
  final DateTime askedAt;
  final bool isAnswered;
  final String? answerText;
  final int? answeredBy;
  final DateTime? answeredAt;

  // Optional nested details
  final String? sessionTitle;
  final String? participantName;
  final String? answererName;

  SessionQuestionModel({
    required this.id,
    required this.sessionId,
    required this.participantId,
    required this.questionText,
    required this.askedAt,
    required this.isAnswered,
    this.answerText,
    this.answeredBy,
    this.answeredAt,
    this.sessionTitle,
    this.participantName,
    this.answererName,
  });

  factory SessionQuestionModel.fromJson(Map<String, dynamic> json) {
    return SessionQuestionModel(
      id: json['id'] ?? '',
      sessionId: json['session'] ?? '',
      participantId: json['participant'] ?? '',
      questionText: json['question_text'] ?? '',
      askedAt: json['asked_at'] != null
          ? DateTime.parse(json['asked_at'])
          : DateTime.now(),
      isAnswered: json['is_answered'] ?? false,
      answerText: json['answer_text'],
      answeredBy: json['answered_by'],
      answeredAt: json['answered_at'] != null
          ? DateTime.parse(json['answered_at'])
          : null,
      sessionTitle: json['session_title'],
      participantName: json['participant_name'],
      answererName: json['answerer_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session': sessionId,
      'participant': participantId,
      'question_text': questionText,
      'asked_at': askedAt.toIso8601String(),
      'is_answered': isAnswered,
      'answer_text': answerText,
      'answered_by': answeredBy,
      'answered_at': answeredAt?.toIso8601String(),
      'session_title': sessionTitle,
      'participant_name': participantName,
      'answerer_name': answererName,
    };
  }

  String get formattedAskedAt {
    final now = DateTime.now();
    final difference = now.difference(askedAt);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return '${askedAt.day}/${askedAt.month}/${askedAt.year}';
    }
  }
}
