import 'package:dio/dio.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/event_model.dart';

/// Event Service
/// Handles all event, room, and session related API calls
class EventService {
  final ApiClient _apiClient;

  EventService(this._apiClient);

  // ==================== EVENT ENDPOINTS ====================

  /// Get all events
  Future<List<EventModel>> getEvents({
    String? status,
    String? search,
    int? page,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (page != null) queryParams['page'] = page;

      final response = await _apiClient.get(
        ApiConstants.events,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] ?? data;
        
        if (results is List) {
          return results.map((e) => EventModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load events');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Get event by ID
  Future<EventModel> getEvent(String id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.eventDetail(id),
      );

      if (response.statusCode == 200) {
        return EventModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load event');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Get event statistics
  Future<Map<String, dynamic>> getEventStatistics(String eventId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.eventStatistics(eventId),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load statistics');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ==================== ROOM ENDPOINTS ====================

  /// Get all rooms
  Future<List<Room>> getRooms({
    String? eventId,
    bool? isActive,
    int? page,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (eventId != null) queryParams['event'] = eventId;
      if (isActive != null) queryParams['is_active'] = isActive;
      if (page != null) queryParams['page'] = page;

      final response = await _apiClient.get(
        ApiConstants.rooms,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] ?? data;
        
        if (results is List) {
          return results.map((e) => Room.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load rooms');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Get room by ID
  Future<Room> getRoom(String id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.roomDetail(id),
      );

      if (response.statusCode == 200) {
        return Room.fromJson(response.data);
      } else {
        throw Exception('Failed to load room');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Get room sessions
  Future<List<Session>> getRoomSessions(String roomId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.roomSessions(roomId),
      );

      if (response.statusCode == 200) {
        final results = response.data as List;
        return results.map((e) => Session.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load room sessions');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Get current session in room
  Future<Session?> getCurrentSession(String roomId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.roomCurrentSession(roomId),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is Map<String, dynamic>) {
          return Session.fromJson(data);
        }
        return null;
      } else {
        return null;
      }
    } on DioException catch (e) {
      // Return null if no current session
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception(_handleError(e));
    }
  }

  // ==================== SESSION ENDPOINTS ====================

  /// Get all sessions
  Future<List<Session>> getSessions({
    String? eventId,
    String? roomId,
    String? status,
    String? theme,
    String? search,
    int? page,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (eventId != null) queryParams['event'] = eventId;
      if (roomId != null) queryParams['room'] = roomId;
      if (status != null) queryParams['status'] = status;
      if (theme != null) queryParams['theme'] = theme;
      if (search != null) queryParams['search'] = search;
      if (page != null) queryParams['page'] = page;

      final response = await _apiClient.get(
        ApiConstants.sessions,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] ?? data;
        
        if (results is List) {
          return results.map((e) => Session.fromJson(e)).toList();
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
  Future<Session> getSession(String id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.sessionDetail(id),
      );

      if (response.statusCode == 200) {
        return Session.fromJson(response.data);
      } else {
        throw Exception('Failed to load session');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Get live sessions
  Future<List<Session>> getLiveSessions({String? eventId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (eventId != null) queryParams['event'] = eventId;

      final response = await _apiClient.get(
        ApiConstants.sessionLive,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final results = response.data as List;
        return results.map((e) => Session.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load live sessions');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Start a session
  Future<Session> startSession(String sessionId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.sessionStart(sessionId),
      );

      if (response.statusCode == 200) {
        return Session.fromJson(response.data);
      } else {
        throw Exception('Failed to start session');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// End a session
  Future<Session> endSession(String sessionId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.sessionEnd(sessionId),
      );

      if (response.statusCode == 200) {
        return Session.fromJson(response.data);
      } else {
        throw Exception('Failed to end session');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ==================== DASHBOARD ====================

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats({String? eventId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (eventId != null) queryParams['event_id'] = eventId;

      final response = await _apiClient.get(
        ApiConstants.dashboardStats,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load dashboard statistics');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ==================== HELPER METHODS ====================

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