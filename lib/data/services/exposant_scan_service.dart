import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/exposant_scan_model.dart';

/// Exposant Scan Service
/// Handles booth visit tracking when exposants scan participant QR codes
class ExposantScanService {
  final ApiClient _apiClient;

  ExposantScanService(this._apiClient);

  /// Scan participant QR code (create booth visit record)
  Future<ExposantScanModel> scanParticipant({
    required String exposantId,
    required String scannedParticipantId,
    required String eventId,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/exposant-scans/',
        data: {
          'exposant': exposantId,
          'scanned_participant': scannedParticipantId,
          'event': eventId,
          'notes': notes,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ExposantScanModel.fromJson(response.data);
      } else {
        throw Exception('Failed to record scan');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Get my scans with statistics (exposant only)
  Future<Map<String, dynamic>> getMyScans({required String eventId}) async {
    try {
      final response = await _apiClient.get(
        '/exposant-scans/my_scans/',
        queryParameters: {'event_id': eventId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'total_visits': data['total_visits'] ?? 0,
          'today_visits': data['today_visits'] ?? 0,
          'scans': (data['scans'] as List?)
                  ?.map((e) => ExposantScanModel.fromJson(e))
                  .toList() ??
              [],
        };
      } else {
        throw Exception('Failed to load scans');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Get all scans (with filters)
  Future<List<ExposantScanModel>> getScans({
    String? exposantId,
    String? eventId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (exposantId != null) queryParams['exposant_id'] = exposantId;
      if (eventId != null) queryParams['event_id'] = eventId;

      final response = await _apiClient.get(
        '/exposant-scans/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] ?? data;

        if (results is List) {
          return results.map((e) => ExposantScanModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load scans');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Get scan by ID
  Future<ExposantScanModel> getScan(String id) async {
    try {
      final response = await _apiClient.get('/exposant-scans/$id/');

      if (response.statusCode == 200) {
        return ExposantScanModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load scan');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Export scans to Excel file
  /// Downloads Excel file with all visits across all events
  Future<dynamic> exportToExcel() async {
    try {
      final response = await _apiClient.get(
        '/exposant-scans/export_excel/',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': '*/*', // Accept any content type
          },
        ),
      );

      if (response.statusCode == 200) {
        // Return the bytes for the caller to handle file saving
        return response.data;
      } else {
        throw Exception('Failed to export Excel');
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
