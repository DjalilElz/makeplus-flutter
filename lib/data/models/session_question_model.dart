/// Session Question Model
///
/// Anonymous by design: the backend's SessionQuestionSerializer never
/// returns asker identity (`participant` is write_only) -- there is no
/// participant id/name field here to match, on purpose.
class SessionQuestionModel {
  final String id;
  final String sessionId;
  final String questionText;
  final DateTime askedAt;
  final bool isAnswered;
  final String? answerText;
  final int? answeredBy;
  final DateTime? answeredAt;

  // Optional nested details
  final String? sessionTitle;
  final String? answeredByName;

  SessionQuestionModel({
    required this.id,
    required this.sessionId,
    required this.questionText,
    required this.askedAt,
    required this.isAnswered,
    this.answerText,
    this.answeredBy,
    this.answeredAt,
    this.sessionTitle,
    this.answeredByName,
  });

  factory SessionQuestionModel.fromJson(Map<String, dynamic> json) {
    return SessionQuestionModel(
      id: json['id']?.toString() ?? '',
      sessionId: json['session'] ?? '',
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
      answeredByName: json['answered_by_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session': sessionId,
      'question_text': questionText,
      'asked_at': askedAt.toIso8601String(),
      'is_answered': isAnswered,
      'answer_text': answerText,
      'answered_by': answeredBy,
      'answered_at': answeredAt?.toIso8601String(),
      'session_title': sessionTitle,
      'answered_by_name': answeredByName,
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
