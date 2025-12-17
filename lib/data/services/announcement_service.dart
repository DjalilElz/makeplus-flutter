import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/announcement_model.dart';

/// Announcement Service
/// Handles event announcements with role-based targeting
class AnnouncementService {
  final ApiClient _apiClient;

  AnnouncementService(this._apiClient);

  /// Get announcements (automatically filtered by user's role)
  Future<List<AnnouncementModel>> getAnnouncements({
    String? eventId,
    String? target,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (eventId != null) queryParams['event_id'] = eventId;
      if (target != null) queryParams['target'] = target;
      if (search != null) queryParams['search'] = search;

      print('📢 ANNOUNCEMENT SERVICE - Query params: $queryParams');

      final response = await _apiClient.get(
        '/annonces/',
        queryParameters: queryParams,
      );

      print(
          '📢 ANNOUNCEMENT SERVICE - Response status: ${response.statusCode}');
      print('📢 ANNOUNCEMENT SERVICE - Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] ?? data;

        if (results is List) {
          print(
              '📢 ANNOUNCEMENT SERVICE - Found ${results.length} announcements');
          return results.map((e) => AnnouncementModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load announcements');
      }
    } on DioException catch (e) {
      print('❌ ANNOUNCEMENT SERVICE ERROR: ${e.response?.data}');
      throw Exception(_handleError(e));
    }
  }

  /// Get announcement by ID
  Future<AnnouncementModel> getAnnouncement(String id) async {
    try {
      final response = await _apiClient.get('/annonces/$id/');

      if (response.statusCode == 200) {
        return AnnouncementModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load announcement');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Create announcement
  Future<AnnouncementModel> createAnnouncement({
    required String eventId,
    required String title,
    required String description,
    required String target, // 'all', 'participants', 'exposants', etc.
  }) async {
    try {
      final response = await _apiClient.post(
        '/annonces/',
        data: {
          'event': eventId,
          'title': title,
          'description': description,
          'target': target,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AnnouncementModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create announcement');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Update announcement (owner or gestionnaire only)
  Future<AnnouncementModel> updateAnnouncement({
    required String id,
    String? title,
    String? description,
    String? target,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (target != null) data['target'] = target;

      final response = await _apiClient.patch('/annonces/$id/', data: data);

      if (response.statusCode == 200) {
        return AnnouncementModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update announcement');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Delete announcement (owner or gestionnaire only)
  Future<void> deleteAnnouncement(String id) async {
    try {
      final response = await _apiClient.delete('/annonces/$id/');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete announcement');
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
