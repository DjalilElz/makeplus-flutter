// lib/data/repositories/auth_repository.dart

import '../models/user_model.dart';
import '../services/supabase_auth_service.dart';
import '../services/django_api_service.dart';

class AuthRepository {
  final SupabaseAuthService authService;
  final DjangoApiService apiService;

  AuthRepository({
    required this.authService,
    required this.apiService,
  });

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = await authService.getCurrentUserProfile();
      return user;
    } catch (e) {
      return null;
    }
  }

  // Login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Supabase
      final user = await authService.signIn(
        email: email,
        password: password,
      );

      // Set Django API token
      final supabaseUser = authService.currentUser;
      if (supabaseUser != null) {
        final session = supabaseUser.id;
        apiService.setAuthToken(session);
      }

      return user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Sign up
  Future<UserModel> signup({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // Sign up with Supabase
      final user = await authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      // Set Django API token
      final supabaseUser = authService.currentUser;
      if (supabaseUser != null) {
        final session = supabaseUser.id;
        apiService.setAuthToken(session);
      }

      return user;
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await authService.signOut();
      // Clear Django API token
      apiService.setAuthToken('');
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await authService.resetPassword(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Update profile
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final updatedUser = await authService.updateProfile(
        userId: userId,
        name: name,
        phone: phone,
        photoUrl: photoUrl,
      );
      return updatedUser;
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return authService.currentUser != null;
  }
}