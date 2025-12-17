import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/room_model.dart';

/// Room Service
/// Handles room management operations
class RoomService {
  final ApiClient _apiClient;

  RoomService(this._apiClient);

  /// Get all rooms
  Future<List<RoomModel>> getRooms({String? eventId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (eventId != null) queryParams['event_id'] = eventId;

      print('🏢 FETCHING ROOMS - Event ID: $eventId');

      final response = await _apiClient.get(
        '/rooms/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] ?? data;

        if (results is List) {
          print('🏢 ROOMS LOADED - Count: ${results.length}');
          return results.map((e) => RoomModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load rooms');
      }
    } on DioException catch (e) {
      print('❌ ERROR LOADING ROOMS: $e');
      throw Exception(_handleError(e));
    }
  }

  /// Get the room assigned to a user (for room managers)
  Future<RoomModel?> getAssignedRoom({
    required String userId,
    required String eventId,
  }) async {
    try {
      print('🔍 FETCHING ASSIGNED ROOM - User ID: $userId, Event ID: $eventId');

      // First, get the user's room assignment
      final assignmentResponse = await _apiClient.get(
        '/room-assignments/',
        queryParameters: {
          'user_id': userId,
          'event_id': eventId,
          'is_active': true,
        },
      );

      if (assignmentResponse.statusCode == 200) {
        final assignmentData = assignmentResponse.data;
        final assignments = assignmentData['results'] ?? assignmentData;

        if (assignments is List && assignments.isNotEmpty) {
          // Get the first active assignment
          final assignment = assignments.first;
          final roomId = assignment['room'];

          print('✅ FOUND ASSIGNMENT - Room ID: $roomId');

          // Now fetch the room details
          final room = await getRoom(roomId.toString());
          return room;
        } else {
          print('⚠️ NO ROOM ASSIGNMENT FOUND');
          return null;
        }
      } else {
        throw Exception('Failed to fetch room assignment');
      }
    } on DioException catch (e) {
      print('❌ ERROR LOADING ASSIGNED ROOM: $e');
      throw Exception(_handleError(e));
    }
  }

  /// Get room by ID
  Future<RoomModel> getRoom(String id) async {
    try {
      final response = await _apiClient.get('/rooms/$id/');

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
