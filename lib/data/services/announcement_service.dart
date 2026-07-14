import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/announcement_model.dart';
import 'package:makeplus/core/utils/app_logger.dart';

/// Announcement Service
/// Handles event announcements with role-based targeting
class AnnouncementService {
  final ApiClient _apiClient;

  AnnouncementService(this._apiClient);

  /// Get announcements (automatically filtered by user's role and event from JWT)
  /// IMPORTANT: Do not pass event_id parameter - backend filters automatically based on JWT token
  Future<List<AnnouncementModel>> getAnnouncements({
    String? target,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      // DO NOT add event_id - backend filters automatically from JWT
      if (target != null) queryParams['target'] = target;
      if (search != null) queryParams['search'] = search;

      // Add timestamp to bypass CloudFlare CDN cache
      // This forces a unique URL for each request, preventing stale cached data
      queryParams['_t'] = DateTime.now().millisecondsSinceEpoch.toString();

      AppLogger.d('📢 ANNOUNCEMENT SERVICE - Query params: $queryParams');

      final response = await _apiClient.get(
        '/annonces/',
        queryParameters: queryParams,
      );

      AppLogger.d(
          '📢 ANNOUNCEMENT SERVICE - Response status: ${response.statusCode}');
      AppLogger.d('📢 ANNOUNCEMENT SERVICE - Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] ?? data;

        if (results is List) {
          AppLogger.d(
              '📢 ANNOUNCEMENT SERVICE - Found ${results.length} announcements');
          for (var announcement in results) {
            AppLogger.d('  - ${announcement['title']} (ID: ${announcement['id']})');
          }
          return results.map((e) => AnnouncementModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load announcements');
      }
    } on DioException catch (e) {
      AppLogger.d('❌ ANNOUNCEMENT SERVICE ERROR: ${e.response?.data}');
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
      AppLogger.d('📢 ANNOUNCEMENT SERVICE - Creating announcement...');
      AppLogger.d('   Event ID: $eventId');
      AppLogger.d('   Title: $title');
      AppLogger.d('   Target: $target');

      final response = await _apiClient.post(
        '/annonces/',
        data: {
          'event': eventId,
          'title': title,
          'description': description,
          'target': target,
        },
      );

      AppLogger.d(
          '📢 ANNOUNCEMENT SERVICE - Create response status: ${response.statusCode}');
      AppLogger.d('📢 ANNOUNCEMENT SERVICE - Created announcement: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AnnouncementModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create announcement');
      }
    } on DioException catch (e) {
      AppLogger.d('❌ ANNOUNCEMENT SERVICE - Create error: ${e.response?.data}');
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
