import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_client.dart';

/// Authentication Service
/// Handles all authentication-related API calls
class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  /// Login user with credentials
  /// Returns AuthResponse containing user data and tokens
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.tokenLogin,
        data: {
          'email': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        // Save tokens
        await _apiClient.saveTokens(
          authResponse.tokens.access,
          authResponse.tokens.refresh,
        );

        return authResponse;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['message'] ??
            e.response?.data['detail'] ??
            'Login failed';
        throw Exception(errorMessage);
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Register new user
  /// NOTE: Registration is NOT available in mobile app per backend specification
  /// Users are created by administrators only
  Future<AuthResponse> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required String confirmPassword,
  }) async {
    throw Exception('Registration is not available in the mobile app. '
        'Users must be created by event administrators.');
  }

  /// Logout user
  /// NOTE: Logout endpoint is NOT available in mobile app per backend specification
  /// Only clears local tokens (no backend blacklist)
  Future<void> logout() async {
    // Clear local tokens only - no API call needed
    await _apiClient.clearTokens();
  }

  /// Get current user profile
  Future<UserModel> getProfile() async {
    try {
      final response = await _apiClient.get(ApiConstants.profile);

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load profile');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'Failed to load profile');
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (email != null) data['email'] = email;
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;

      final response = await _apiClient.patch(
        ApiConstants.profile,
        data: data,
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update profile');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'Failed to update profile');
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Change user password
  /// NOTE: Change password is NOT available in mobile app per backend specification
  /// Password changes must be done through the admin dashboard
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    throw Exception('Password change is not available in the mobile app. '
        'Please contact event administrators to change your password.');
  }

  /// Verify if token is still valid
  Future<bool> verifyToken() async {
    try {
      final accessToken = await _apiClient.getAccessToken();
      if (accessToken == null) return false;

      final response = await _apiClient.post(
        ApiConstants.tokenVerify,
        data: {'token': accessToken},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _apiClient.isAuthenticated();
  }
}
