// lib/data/services/django_api_service.dart

import 'package:dio/dio.dart';
import '../models/room_model.dart';

class DjangoApiService {
  late final Dio _dio;
  
  // Replace with your Django backend URL
  static const String baseUrl = 'https://makeplus-django-5.onrender.com';

  DjangoApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add authorization token if available
          // options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle errors globally
          return handler.next(error);
        },
      ),
    );
  }

  // Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // ==================== ROOMS API ====================

  // Get all rooms
  Future<List<RoomModel>> getRooms({String? eventId}) async {
    try {
      final response = await _dio.get(
        '/rooms/',
        queryParameters: eventId != null ? {'event_id': eventId} : null,
      );
      
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => RoomModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch rooms: $e');
    }
  }

  // Get room by ID
  Future<RoomModel> getRoom(String roomId) async {
    try {
      final response = await _dio.get('/rooms/$roomId/');
      return RoomModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch room: $e');
    }
  }

  // Create room
  Future<RoomModel> createRoom(Map<String, dynamic> roomData) async {
    try {
      final response = await _dio.post('/rooms/', data: roomData);
      return RoomModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  // Update room
  Future<RoomModel> updateRoom(String roomId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch('/rooms/$roomId/', data: updates);
      return RoomModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  // Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      await _dio.delete('/rooms/$roomId/');
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }

  // ==================== SESSIONS API ====================

  // Get sessions for a room
  Future<List<SessionModel>> getRoomSessions(String roomId) async {
    try {
      final response = await _dio.get('/sessions/', 
        queryParameters: {'room_id': roomId},
      );
      
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => SessionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch sessions: $e');
    }
  }

  // Create session
  Future<SessionModel> createSession(Map<String, dynamic> sessionData) async {
    try {
      final response = await _dio.post('/sessions/', data: sessionData);
      return SessionModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  // Update session
  Future<SessionModel> updateSession(
    String sessionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _dio.patch('/sessions/$sessionId/', data: updates);
      return SessionModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _dio.delete('/sessions/$sessionId/');
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // ==================== PARTICIPANTS API ====================

  // Get participants
  Future<List<Map<String, dynamic>>> getParticipants({
    String? roomId,
    String? sessionId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (roomId != null) queryParams['room_id'] = roomId;
      if (sessionId != null) queryParams['session_id'] = sessionId;

      final response = await _dio.get(
        '/participants/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      return List<Map<String, dynamic>>.from(
        response.data['results'] ?? response.data,
      );
    } catch (e) {
      throw Exception('Failed to fetch participants: $e');
    }
  }

  // Verify participant badge
  Future<Map<String, dynamic>> verifyBadge(String qrData) async {
    try {
      final response = await _dio.post('/participants/verify/', data: {
        'qr_data': qrData,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to verify badge: $e');
    }
  }

  // ==================== EVENTS API ====================

  // Get events
  Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final response = await _dio.get('/events/');
      return List<Map<String, dynamic>>.from(
        response.data['results'] ?? response.data,
      );
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  // Get event details
  Future<Map<String, dynamic>> getEvent(String eventId) async {
    try {
      final response = await _dio.get('/events/$eventId/');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }

  // ==================== ANNOUNCEMENTS API ====================

  // Get announcements
  Future<List<Map<String, dynamic>>> getAnnouncements({String? eventId}) async {
    try {
      final response = await _dio.get(
        '/announcements/',
        queryParameters: eventId != null ? {'event_id': eventId} : null,
      );
      return List<Map<String, dynamic>>.from(
        response.data['results'] ?? response.data,
      );
    } catch (e) {
      throw Exception('Failed to fetch announcements: $e');
    }
  }

  // Create announcement
  Future<Map<String, dynamic>> createAnnouncement(
    Map<String, dynamic> announcementData,
  ) async {
    try {
      final response = await _dio.post(
        '/announcements/',
        data: announcementData,
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  // ==================== EXHIBITORS API ====================

  // Get exhibitors
  Future<List<Map<String, dynamic>>> getExhibitors({String? eventId}) async {
    try {
      final response = await _dio.get(
        '/exhibitors/',
        queryParameters: eventId != null ? {'event_id': eventId} : null,
      );
      return List<Map<String, dynamic>>.from(
        response.data['results'] ?? response.data,
      );
    } catch (e) {
      throw Exception('Failed to fetch exhibitors: $e');
    }
  }

  // Get exhibitor details
  Future<Map<String, dynamic>> getExhibitor(String exhibitorId) async {
    try {
      final response = await _dio.get('/exhibitors/$exhibitorId/');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch exhibitor: $e');
    }
  }

  // ==================== STATISTICS API ====================

  // Get statistics
  Future<Map<String, dynamic>> getStats({
    String? eventId,
    String? roomId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (eventId != null) queryParams['event_id'] = eventId;
      if (roomId != null) queryParams['room_id'] = roomId;

      final response = await _dio.get(
        '/statistics/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }
}