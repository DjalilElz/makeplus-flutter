import 'package:dio/dio.dart';

import '../models/room_model.dart';
import 'api_client.dart';
import 'package:makeplus/core/utils/app_logger.dart';

/// Session Service
/// Handles session management and status control
class SessionService {
  final ApiClient _apiClient;

  SessionService(this._apiClient);

  /// Get all sessions
  Future<List<SessionModel>> getSessions({
    String? roomId,
    String? eventId,
    String? status,
    String? sessionType,
    bool? isPaid,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (roomId != null) queryParams['room'] = roomId;
      if (eventId != null) queryParams['event'] = eventId;
      if (status != null) queryParams['status'] = status;
      if (sessionType != null) queryParams['session_type'] = sessionType;
      if (isPaid != null) queryParams['is_paid'] = isPaid;

      final response = await _apiClient.get(
        '/sessions/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] ?? data;

        if (results is List) {
          return results.map((e) => SessionModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load sessions');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Get session by ID
  Future<SessionModel> getSession(String id) async {
    try {
      final response = await _apiClient.get('/sessions/$id/');

      if (response.statusCode == 200) {
        return SessionModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load session');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Create session (gestionnaire only)
  Future<SessionModel> createSession({
    required String eventId,
    required String roomId,
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? speakerName,
    String? speakerTitle,
    String? theme,
    String sessionType = 'conference',
    bool isPaid = false,
    double? price,
    String? youtubeLiveUrl,
  }) async {
    try {
      final response = await _apiClient.post(
        '/sessions/',
        data: {
          'event': eventId,
          'room': roomId,
          'title': title,
          'description': description,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'speaker_name': speakerName,
          'speaker_title': speakerTitle,
          'theme': theme,
          'session_type': sessionType,
          'is_paid': isPaid,
          'price': price?.toString(),
          'youtube_live_url': youtubeLiveUrl,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return SessionModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create session');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Update session (gestionnaire only)
  Future<SessionModel> updateSession({
    required String id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? speakerName,
    String? speakerTitle,
    String? theme,
    String? sessionType,
    bool? isPaid,
    double? price,
    String? youtubeLiveUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (startTime != null) data['start_time'] = startTime.toIso8601String();
      if (endTime != null) data['end_time'] = endTime.toIso8601String();
      if (speakerName != null) data['speaker_name'] = speakerName;
      if (speakerTitle != null) data['speaker_title'] = speakerTitle;
      if (theme != null) data['theme'] = theme;
      if (sessionType != null) data['session_type'] = sessionType;
      if (isPaid != null) data['is_paid'] = isPaid;
      if (price != null) data['price'] = price.toString();
      if (youtubeLiveUrl != null) data['youtube_live_url'] = youtubeLiveUrl;

      final response = await _apiClient.patch('/sessions/$id/', data: data);

      if (response.statusCode == 200) {
        return SessionModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update session');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Delete session (gestionnaire only)
  Future<void> deleteSession(String id) async {
    try {
      final response = await _apiClient.delete('/sessions/$id/');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete session');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Start session (mark as live) - gestionnaire only
  /// Uses backend alias /start/ endpoint
  Future<SessionModel> startSession(String sessionId) async {
    try {
      final response = await _apiClient.post('/sessions/$sessionId/start/');

      if (response.statusCode == 200) {
        final payload = response.data;
        final sessionData = payload is Map<String, dynamic>
            ? (payload['session'] ?? payload)
            : payload;
        return SessionModel.fromJson(sessionData as Map<String, dynamic>);
      } else {
        throw Exception('Failed to start session');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// End session (mark as completed) - gestionnaire only
  /// Uses backend alias /end/ endpoint
  Future<SessionModel> endSession(String sessionId) async {
    try {
      final response = await _apiClient.post('/sessions/$sessionId/end/');

      if (response.statusCode == 200) {
        final payload = response.data;
        final sessionData = payload is Map<String, dynamic>
            ? (payload['session'] ?? payload)
            : payload;
        return SessionModel.fromJson(sessionData as Map<String, dynamic>);
      } else {
        throw Exception('Failed to end session');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Cancel session (reset to not started) - gestionnaire only
  Future<SessionModel> cancelSession(String sessionId) async {
    try {
      final response = await _apiClient.post('/sessions/$sessionId/cancel/');

      if (response.statusCode == 200) {
        final payload = response.data;
        final sessionData = payload is Map<String, dynamic>
            ? (payload['session'] ?? payload)
            : payload;
        return SessionModel.fromJson(sessionData as Map<String, dynamic>);
      } else {
        throw Exception('Failed to cancel session');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Swap session times (room manager only)
  /// Swaps start_time and end_time between two sessions in the same room
  Future<Map<String, dynamic>> swapSessionTimes(
    String session1Id,
    String session2Id,
  ) async {
    try {
      AppLogger.d(
          '🔄 SWAPPING SESSION TIMES - Session 1: $session1Id, Session 2: $session2Id');

      final response = await _apiClient.post(
        '/sessions/swap-times/',
        data: {
          'session_1_id': session1Id,
          'session_2_id': session2Id,
        },
      );

      AppLogger.d('📡 Swap Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        AppLogger.d('✅ SESSIONS SWAPPED SUCCESSFULLY');
        return data;
      } else {
        throw Exception('Failed to swap session times');
      }
    } on DioException catch (e) {
      AppLogger.d('❌ ERROR SWAPPING SESSIONS: ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          throw Exception(errorData['message'] ??
              errorData['error'] ??
              'Cannot swap sessions');
        }
      } else if (e.response?.statusCode == 404) {
        throw Exception('One or both sessions not found');
      }

      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map) {
        return data['message'] ?? data['detail'] ?? 'An error occurred';
      }
      return 'An error occurred';
    }
    return 'Network error. Please check your connection.';
  }
}
