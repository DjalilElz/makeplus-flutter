// lib/data/services/eposter_service.dart

import 'package:dio/dio.dart';

import '../models/eposter_gallery_item.dart';
import 'api_client.dart';

/// ePoster service -- currently just the public gallery of accepted
/// final submissions for an event.
class EposterService {
  final ApiClient _apiClient;

  EposterService(this._apiClient);

  Future<List<EposterGalleryItem>> getGallery({
    required String eventId,
    String? query,
  }) async {
    try {
      final response = await _apiClient.get(
        '/eposter/$eventId/gallery/',
        queryParameters: (query != null && query.isNotEmpty) ? {'q': query} : null,
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List? ?? [];
        return results
            .map((e) => EposterGalleryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load gallery');
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
