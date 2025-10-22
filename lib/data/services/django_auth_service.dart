import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class DjangoAuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://makeplus-django-5.onrender.com/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  String? _token;
  SharedPreferences? _prefs;

  DjangoAuthService() {
    _initPrefs();
    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs?.getString('auth_token');
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  /// Login with email and password
  Future<UserModel> login(String email, String password) async {
    try {
      print('🔵 LOGIN - Starting login for: $email');

      final response = await _dio.post(
        '/auth/login/',
        data: {
          'email': email,
          'password': password,
        },
      );

      print('✅ LOGIN - Response: ${response.statusCode}');
      print('📦 LOGIN - Data: ${response.data}');

      // Extract access token from the response
      final tokens = response.data['tokens'];
      if (tokens != null && tokens['access'] != null) {
        _token = tokens['access'];
        _dio.options.headers['Authorization'] = 'Bearer $_token';
        await _prefs?.setString('auth_token', _token!);
      }

      // Store user data
      await _prefs?.setString('user_data', response.data['user'].toString());

      // Store role if available
      if (response.data['role'] != null) {
        await _prefs?.setString('user_role', response.data['role']);
      }

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      print('❌ LOGIN ERROR: ${e.response?.statusCode}');
      print('📍 ERROR DATA: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  /// Signup/Register
  Future<UserModel> signup({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      print('🔵 SIGNUP - Starting signup for: $email');
      
      final nameParts = name.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final response = await _dio.post(
        '/auth/register/',
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
        },
      );

      print('✅ SIGNUP - Success: ${response.statusCode}');

      // Auto-login after signup
      return await login(email, password);
    } on DioException catch (e) {
      print('❌ SIGNUP ERROR: ${e.response?.statusCode}');
      throw _handleError(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout/');
    } catch (e) {
      print('⚠️ Logout error (ignored): $e');
    } finally {
      _token = null;
      _dio.options.headers.remove('Authorization');
      await _prefs?.remove('auth_token');
      await _prefs?.remove('user_data');
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    if (_token == null) {
      print('⚠️ No token found');
      return null;
    }

    try {
      final response = await _dio.get('/auth/me/');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ GET USER ERROR: ${e.response?.statusCode}');
      if (e.response?.statusCode == 401) {
        await logout();
      }
      return null;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _dio.post(
        '/auth/password-reset/',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      
      // Handle different error formats
      if (data is Map) {
        if (data.containsKey('error')) {
          return data['error'].toString();
        }
        if (data.containsKey('detail')) {
          return data['detail'].toString();
        }
        if (data.containsKey('non_field_errors')) {
          return data['non_field_errors'][0].toString();
        }
        // Return first error message found
        return data.values.first.toString();
      }
      return data.toString();
    }
    
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server is taking too long to respond.';
    }
    
    return e.message ?? 'Network error occurred';
  }
}