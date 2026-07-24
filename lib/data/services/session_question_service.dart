import 'package:dio/dio.dart';

import '../models/session_question_model.dart';
import 'api_client.dart';

/// Session Q&A service.
///
/// The backend never returns asker identity (SessionQuestionSerializer's
/// `participant` field is write_only) — every question in every response is
/// already anonymous by the time it reaches this app. Nothing here needs to
/// hide or filter anything further.
class SessionQuestionService {
  final ApiClient _apiClient;

  SessionQuestionService(this._apiClient);

  /// Questions for one session, oldest first (matches backend ordering).
  Future<List<SessionQuestionModel>> getQuestions(String sessionId) async {
    try {
      final response = await _apiClient.get(
        '/session-questions/',
        queryParameters: {'session': sessionId},
      );

      final data = response.data;
      final results = data['results'] ?? data;
      if (results is List) {
        return results
            .map((e) => SessionQuestionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Ask a question. The backend extracts the asker from the JWT — never send
  /// a participant id from the client.
  Future<SessionQuestionModel> askQuestion({
    required String sessionId,
    required String questionText,
  }) async {
    try {
      final response = await _apiClient.post(
        '/session-questions/',
        data: {
          'session': sessionId,
          'question_text': questionText,
        },
      );
      return SessionQuestionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Answer a question. Gestionnaire-only on the backend; [answerText] must
  /// be non-empty (the DRF `answer` action rejects an empty string with a
  /// 400 -- unlike the web dashboard's equivalent view, this endpoint has no
  /// "clear the answer" mode).
  Future<SessionQuestionModel> answerQuestion({
    required String questionId,
    required String answerText,
  }) async {
    try {
      final response = await _apiClient.post(
        '/session-questions/$questionId/answer/',
        data: {'answer_text': answerText},
      );
      return SessionQuestionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map) {
        return data['error'] ?? data['message'] ?? data['detail'] ?? 'Une erreur est survenue';
      }
      return 'Une erreur est survenue';
    }
    return 'Erreur réseau. Vérifiez votre connexion.';
  }
}
