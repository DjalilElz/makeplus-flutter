import 'package:dio/dio.dart';

import '../models/room_model.dart';
import 'api_client.dart';
import 'package:makeplus/core/utils/app_logger.dart';

/// Room Service
/// Handles room management operations
class RoomService {
  final ApiClient _apiClient;

  RoomService(this._apiClient);

  /// Get all rooms for an event
  /// ⚠️ CRITICAL: Use /api/rooms/?event={eventId} NOT /api/events/{eventId}/rooms/
  Future<List<RoomModel>> getRooms({String? eventId}) async {
    try {
      AppLogger.d('🏢 FETCHING ROOMS - Event ID: $eventId');

      // ✅ CORRECT: Use /rooms/ endpoint with event query parameter
      final endpoint = '/rooms/';
      final queryParameters = eventId != null ? {'event': eventId} : null;

      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] ?? data;

        if (results is List) {
          AppLogger.d('🏢 ROOMS LOADED - Count: ${results.length}');
          return results.map((e) => RoomModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load rooms');
      }
    } on DioException catch (e) {
      AppLogger.d('❌ ERROR LOADING ROOMS: $e');
      throw Exception(_handleError(e));
    }
  }

  /// Get the room assigned to a user (for room managers)
  /// NEW SIMPLIFIED APPROACH: Room assignment is automatically included in /user-assignments/ response
  /// No need for separate API call to /room-assignments/
  Future<RoomModel?> getAssignedRoom({
    required String userId,
    required String eventId,
  }) async {
    try {
      AppLogger.d('🔍 FETCHING ASSIGNED ROOM - User ID: $userId, Event ID: $eventId');

      // Fetch user assignment which includes room_assignment for room managers
      final userAssignmentResponse = await _apiClient.get(
        '/user-assignments/',
        queryParameters: {
          'user': userId,
          'event': eventId,
          'is_active': true,
        },
      );

      AppLogger.d(
          '📡 User Assignment Response Status: ${userAssignmentResponse.statusCode}');

      if (userAssignmentResponse.statusCode == 200) {
        final data = userAssignmentResponse.data;
        final assignments = data is List ? data : (data['results'] ?? []);

        AppLogger.d('📋 FOUND ${assignments.length} USER EVENT ASSIGNMENTS');

        if (assignments is List && assignments.isNotEmpty) {
          // Get the first assignment (should be only one for user+event+active)
          final userAssignment = assignments.first;

          // Extract role and room_assignment
          final role = userAssignment['role'] as String?;
          final roomAssignment = userAssignment['room_assignment'];

          AppLogger.d('👤 USER ROLE: $role');
          AppLogger.d('🏢 ROOM ASSIGNMENT: $roomAssignment');

          // Only room managers (gestionnaire_des_salles) should have room assignments
          if (role == 'gestionnaire_des_salles') {
            if (roomAssignment != null && roomAssignment is Map) {
              // Extract room details from room_assignment object
              final roomId = roomAssignment['room_id'] as String?;
              final roomName = roomAssignment['room_name'] as String?;

              AppLogger.d('🔑 ASSIGNED ROOM ID: $roomId');
              AppLogger.d('🏢 ASSIGNED ROOM NAME: $roomName');

              if (roomId != null && roomId.isNotEmpty) {
                // Fetch full room details using the room ID
                final room = await getRoom(roomId, eventId: eventId);
                AppLogger.d('✅ FOUND ASSIGNED ROOM: ${room.name}');
                return room;
              } else {
                AppLogger.d('⚠️ NO ROOM ID IN ROOM ASSIGNMENT');
                return null;
              }
            } else {
              AppLogger.d('⚠️ NO ROOM ASSIGNMENT FOUND FOR THIS ROOM MANAGER');
              AppLogger.d(
                  '⚠️ Admin must create a RoomAssignment record in Django admin');
              return null;
            }
          } else {
            AppLogger.d('⚠️ USER IS NOT A ROOM MANAGER (role: $role)');
            AppLogger.d(
                '⚠️ Only gestionnaire_des_salles should have room assignments');
            return null;
          }
        } else {
          AppLogger.d('⚠️ NO USER EVENT ASSIGNMENTS FOUND');
          return null;
        }
      } else {
        throw Exception('Failed to fetch user assignments');
      }
    } on DioException catch (e) {
      AppLogger.d('❌ ERROR LOADING ASSIGNED ROOM: $e');
      AppLogger.d('❌ RESPONSE: ${e.response?.data}');
      throw Exception(_handleError(e));
    }
  }

  /// Get room by ID
  /// ⚠️ CRITICAL: Always use /api/rooms/{room_id}/ NOT /api/events/{event_id}/rooms/{room_id}/
  Future<RoomModel> getRoom(String id, {String? eventId}) async {
    try {
      // ✅ CORRECT: Use /rooms/{id}/ endpoint (eventId parameter kept for backward compatibility but not used)
      final endpoint = '/rooms/$id/';

      AppLogger.d('🔍 FETCHING ROOM - Endpoint: $endpoint');

      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        return RoomModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load room');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Create room (gestionnaire only)
  Future<RoomModel> createRoom({
    required String eventId,
    required String name,
    required int capacity,
    String? description,
  }) async {
    try {
      final response = await _apiClient.post(
        '/rooms/',
        data: {
          'event': eventId,
          'name': name,
          'capacity': capacity,
          'description': description,
          'is_active': true,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return RoomModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create room');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Update room (gestionnaire only)
  Future<RoomModel> updateRoom({
    required String id,
    String? name,
    int? capacity,
    String? description,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (capacity != null) data['capacity'] = capacity;
      if (description != null) data['description'] = description;

      final response = await _apiClient.patch('/rooms/$id/', data: data);

      if (response.statusCode == 200) {
        return RoomModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update room');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Delete room (gestionnaire only)
  Future<void> deleteRoom(String id) async {
    try {
      final response = await _apiClient.delete('/rooms/$id/');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete room');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Scan participant badge (badge controller)
  /// NEW SIMPLIFIED ENDPOINT - No room_id required
  /// Fetches fresh payment data from database
  Future<Map<String, dynamic>> scanParticipant({
    required String qrData,
  }) async {
    try {
      AppLogger.d('🔍 SCANNING PARTICIPANT (NEW ENDPOINT)');
      AppLogger.d('📍 Endpoint: /participants/scan/');
      AppLogger.d('📦 QR Data length: ${qrData.length} characters');

      final response = await _apiClient.post(
        '/participants/scan/', // ✅ CORRECT - No /events/ prefix
        data: {'qr_data': qrData},
      );

      AppLogger.d('📡 Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.d('✅ SCAN SUCCESSFUL - Status: ${response.data['status']}');
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to scan participant');
      }
    } on DioException catch (e) {
      AppLogger.d('❌ ERROR SCANNING PARTICIPANT: $e');
      AppLogger.d('❌ Request URL: ${e.requestOptions.uri}');
      AppLogger.d('❌ Request method: ${e.requestOptions.method}');
      AppLogger.d('❌ Response status: ${e.response?.statusCode}');
      AppLogger.d('❌ Response data: ${e.response?.data}');

      // Check if it's a 404 error
      if (e.response?.statusCode == 404) {
        AppLogger.d('');
        AppLogger.d('⚠️  ════════════════════════════════════════════════════════');
        AppLogger.d('⚠️  ENDPOINT NOT FOUND (404)');
        AppLogger.d('⚠️  ════════════════════════════════════════════════════════');
        AppLogger.d(
            '⚠️  The backend endpoint does not exist or is not deployed yet.');
        AppLogger.d('⚠️  ');
        AppLogger.d('⚠️  Expected endpoint: POST /api/participants/scan/');
        AppLogger.d('⚠️  Full URL: ${e.requestOptions.uri}');
        AppLogger.d('⚠️  ');
        AppLogger.d('⚠️  Possible causes:');
        AppLogger.d('⚠️  1. Backend endpoint not deployed yet');
        AppLogger.d('⚠️  2. Endpoint path mismatch');
        AppLogger.d('⚠️  3. Backend server not running');
        AppLogger.d('⚠️  ');
        AppLogger.d('⚠️  Please verify with backend developer that the endpoint');
        AppLogger.d('⚠️  is deployed and accessible.');
        AppLogger.d('⚠️  ════════════════════════════════════════════════════════');
        AppLogger.d('');

        throw Exception(
            'Endpoint not found: ${e.requestOptions.uri}\n\nThe backend endpoint /api/events/participants/scan/ does not exist.\nPlease verify with the backend developer.');
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
