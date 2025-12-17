// lib/data/repositories/auth_repository.dart

import '../models/user_model.dart';
import '../services/django_auth_service.dart';

class AuthRepository {
  final DjangoAuthService _authService;

  AuthRepository({DjangoAuthService? authService})
      : _authService = authService ?? DjangoAuthService();

  /// Login with email and password
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _authService.login(email, password);
    } catch (e) {
      rethrow;
    }
  }

  /// Select event after login (for multi-event users)
  Future<LoginResponse> selectEvent(String eventId) async {
    try {
      return await _authService.selectEvent(eventId);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign up a new user
  Future<LoginResponse> signup({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      return await _authService.signup(
        email: email,
        password: password,
        name: name,
        role: role,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      rethrow;
    }
  }

  /// Get currently authenticated user
  Future<UserModel?> getCurrentUser() async {
    try {
      return await _authService.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  /// Get currently authenticated user with event data
  Future<LoginResponse?> getCurrentUserWithEvent() async {
    try {
      return await _authService.getCurrentUserWithEvent();
    } catch (e) {
      return null;
    }
  }

  /// Request password reset
  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }
}
