// lib/data/repositories/room_repository.dart

import '../models/room_model.dart';
import '../services/django_api_service.dart';

class RoomRepository {
  final DjangoApiService apiService;

  RoomRepository({required this.apiService});

  // Get all rooms
  Future<List<RoomModel>> getRooms({String? eventId}) async {
    try {
      return await apiService.getRooms(eventId: eventId);
    } catch (e) {
      throw Exception('Failed to fetch rooms: $e');
    }
  }

  // Get single room
  Future<RoomModel> getRoom(String roomId) async {
    try {
      return await apiService.getRoom(roomId);
    } catch (e) {
      throw Exception('Failed to fetch room: $e');
    }
  }

  // Create room
  Future<RoomModel> createRoom(Map<String, dynamic> roomData) async {
    try {
      return await apiService.createRoom(roomData);
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  // Update room
  Future<RoomModel> updateRoom(
    String roomId,
    Map<String, dynamic> updates,
  ) async {
    try {
      return await apiService.updateRoom(roomId, updates);
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  // Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      await apiService.deleteRoom(roomId);
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }

  // Get sessions for a room
  Future<List<SessionModel>> getRoomSessions(String roomId) async {
    try {
      return await apiService.getRoomSessions(roomId);
    } catch (e) {
      throw Exception('Failed to fetch sessions: $e');
    }
  }

  // Create session
  Future<SessionModel> createSession(Map<String, dynamic> sessionData) async {
    try {
      return await apiService.createSession(sessionData);
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
      return await apiService.updateSession(sessionId, updates);
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    try {
      await apiService.deleteSession(sessionId);
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }
}