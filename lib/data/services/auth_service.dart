import 'package:dio/dio.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

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
        ApiConstants.login,
        data: {
          'username': username,
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
  /// Returns AuthResponse containing user data and tokens
  Future<AuthResponse> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'username': username,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
          'password2': confirmPassword,
        },
      );

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        // Save tokens
        await _apiClient.saveTokens(
          authResponse.tokens.access,
          authResponse.tokens.refresh,
        );
        
        return authResponse;
      } else {
        throw Exception('Registration failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map) {
          // Handle validation errors
          final errors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              errors.addAll(value.map((e) => e.toString()));
            } else {
              errors.add(value.toString());
            }
          });
          throw Exception(errors.join('\n'));
        }
        throw Exception(data['message'] ?? 'Registration failed');
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Logout user
  /// Blacklists refresh token on backend and clears local tokens
  Future<void> logout() async {
    try {
      final refreshToken = await _apiClient.getRefreshToken();
      
      if (refreshToken != null) {
        await _apiClient.post(
          ApiConstants.logout,
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      // Always clear local tokens
      await _apiClient.clearTokens();
    }
  }

  /// Get current user profile
  Future<User> getProfile() async {
    try {
      final response = await _apiClient.get(ApiConstants.profile);

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        throw Exception('Failed to load profile');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to load profile');
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Update user profile
  Future<User> updateProfile({
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
        return User.fromJson(response.data);
      } else {
        throw Exception('Failed to update profile');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update profile');
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.changePassword,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password2': confirmNewPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to change password');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('details')) {
          final errors = <String>[];
          (data['details'] as Map).forEach((key, value) {
            if (value is List) {
              errors.addAll(value.map((e) => e.toString()));
            }
          });
          throw Exception(errors.join('\n'));
        }
        throw Exception(data['message'] ?? 'Failed to change password');
      }
      throw Exception('Network error. Please check your connection.');
    }
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