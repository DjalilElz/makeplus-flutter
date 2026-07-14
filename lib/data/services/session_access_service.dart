// lib/data/services/session_access_service.dart

import 'package:dio/dio.dart';

import '../models/session_access_model.dart';
import 'api_client.dart';

/// Session Access Service
/// Handles paid session access verification and management
class SessionAccessService {
  final ApiClient _apiClient;

  SessionAccessService(this._apiClient);

  /// Get all session access records for current user
  /// Optionally filter by participant or session
  Future<List<SessionAccessModel>> getSessionAccess({
    String? participantId,
    String? sessionId,
    String? paymentStatus,
    bool? hasAccess,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (participantId != null) queryParams['participant'] = participantId;
      if (sessionId != null) queryParams['session'] = sessionId;
      if (paymentStatus != null) {
        queryParams['payment_status'] = paymentStatus;
      }
      if (hasAccess != null) queryParams['has_access'] = hasAccess;

      final response = await _apiClient.get(
        '/session-access/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] ?? data;

        if (results is List) {
          return results.map((e) => SessionAccessModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load session access');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Get session access by ID
  Future<SessionAccessModel> getSessionAccessDetail(String id) async {
    try {
      final response = await _apiClient.get('/session-access/$id/');

      if (response.statusCode == 200) {
        return SessionAccessModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load session access details');
      }
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Check if a participant has access to a specific session
  /// Returns true if user has paid or session is free
  Future<bool> checkAccess({
    required String participantId,
    required String sessionId,
  }) async {
    try {
      final accessList = await getSessionAccess(
        participantId: participantId,
        sessionId: sessionId,
      );

      if (accessList.isEmpty) {
        return false; // No access record found
      }

      final access = accessList.first;
      return access.canAccess();
    } catch (e) {
      // If error occurs, deny access for safety
      return false;
    }
  }

  /// Get access status for a specific session
  /// Returns SessionAccessModel if found, null otherwise
  Future<SessionAccessModel?> getAccessStatus({
    required String participantId,
    required String sessionId,
  }) async {
    try {
      final accessList = await getSessionAccess(
        participantId: participantId,
        sessionId: sessionId,
      );

      if (accessList.isEmpty) {
        return null;
      }

      return accessList.first;
    } catch (e) {
      return null;
    }
  }

  /// Get all paid sessions the user has access to
  Future<List<SessionAccessModel>> getMyPaidSessions(
      String participantId) async {
    try {
      return await getSessionAccess(
        participantId: participantId,
        paymentStatus: 'paid',
        hasAccess: true,
      );
    } catch (e) {
      throw Exception(_handleError(e as DioException));
    }
  }

  /// Get all pending payments for a participant
  Future<List<SessionAccessModel>> getPendingPayments(
      String participantId) async {
    try {
      return await getSessionAccess(
        participantId: participantId,
        paymentStatus: 'pending',
      );
    } catch (e) {
      throw Exception(_handleError(e as DioException));
    }
  }

  /// Get all free sessions the user has access to
  Future<List<SessionAccessModel>> getFreeSessions(String participantId) async {
    try {
      return await getSessionAccess(
        participantId: participantId,
        paymentStatus: 'free',
        hasAccess: true,
      );
    } catch (e) {
      throw Exception(_handleError(e as DioException));
    }
  }

  /// Get access summary for a participant
  /// Returns counts of paid, pending, and free sessions
  Future<Map<String, int>> getAccessSummary(String participantId) async {
    try {
      final allAccess = await getSessionAccess(participantId: participantId);

      int paidCount = 0;
      int pendingCount = 0;
      int freeCount = 0;

      for (var access in allAccess) {
        switch (access.paymentStatus) {
          case PaymentStatus.paid:
            paidCount++;
            break;
          case PaymentStatus.pending:
            pendingCount++;
            break;
          case PaymentStatus.free:
            freeCount++;
            break;
        }
      }

      return {
        'paid': paidCount,
        'pending': pendingCount,
        'free': freeCount,
        'total': allAccess.length,
      };
    } catch (e) {
      return {
        'paid': 0,
        'pending': 0,
        'free': 0,
        'total': 0,
      };
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
