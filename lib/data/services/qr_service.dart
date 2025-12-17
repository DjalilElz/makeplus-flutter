import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/qr_verification_result.dart';

/// QR Code Service
/// Handles QR code generation and verification
class QRService {
  final ApiClient _apiClient;

  QRService(this._apiClient);

  /// Verify QR code
  /// Used by controllers and exposants to verify participant QR codes
  Future<QRVerificationResult> verifyQRCode({
    required String qrData,
    String? roomId,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'qr_data': qrData,
      };

      if (roomId != null) {
        requestData['room_id'] = roomId;
      }

      final response = await _apiClient.post(
        '/participants/verify/',
        data: requestData,
      );

      if (response.statusCode == 200) {
        return QRVerificationResult.fromJson(response.data);
      } else {
        throw Exception('Failed to verify QR code');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map) {
          // Return invalid result with error message
          return QRVerificationResult(
            valid: false,
            accessGranted: false,
            message: data['message'] ?? data['detail'] ?? 'QR code invalide',
          );
        }
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Generate QR code for a participant
  /// Used by gestionnaires to create participant badges
  Future<Map<String, dynamic>> generateQRCode({
    required String participantId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/qr/generate/',
        data: {'participant_id': participantId},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to generate QR code');
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
