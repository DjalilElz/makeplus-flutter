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

    // Add interceptor to remove auth header from public endpoints
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Remove Authorization header for public endpoints
        final publicEndpoints = ['/auth/login/', '/auth/register/', '/auth/password-reset/'];
        if (publicEndpoints.any((endpoint) => options.path.contains(endpoint))) {
          options.headers.remove('Authorization');
        }
        return handler.next(options);
      },
    ));

    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: true,
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
  Future<LoginResponse> login(String email, String password) async {
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

      // Note: Event data is NOT cached - it's always fresh from API response

      // Parse user and merge with role from API response
      final userData = Map<String, dynamic>.from(response.data['user']);
      // Add the role from the root level of the response to the user data
      if (response.data['role'] != null) {
        userData['role'] = response.data['role'];
        print('🎭 USER ROLE: ${response.data['role']}');
      }

      final user = UserModel.fromJson(userData);
      print('✅ USER MODEL CREATED - Role: ${user.role}');

      // Parse event if available
      EventModel? event;
      if (response.data['event'] != null) {
        print('📋 EVENT DATA: ${response.data['event']}');
        event = EventModel.fromJson(response.data['event']);
        print('🎪 EVENT PARSED - Name: ${event.name}, ID: ${event.id}');
        print('📅 Start: ${event.startDate}, End: ${event.endDate}');
        print('📍 Location: ${event.location}');
      } else {
        print('⚠️ NO EVENT DATA IN RESPONSE');
      }

      return LoginResponse(user: user, event: event);
    } on DioException catch (e) {
      print('❌ LOGIN ERROR: ${e.response?.statusCode}');
      print('📍 ERROR TYPE: ${e.type}');

      // Check if response is HTML (server error)
      if (e.response?.data is String && (e.response?.data as String).contains('<html')) {
        print('⚠️ SERVER ERROR: Backend returned HTML instead of JSON');
        print('💡 This means there\'s an error in your Django backend code');
        throw Exception('Server error: Please check your Django backend logs. The login endpoint is returning an HTML error page instead of JSON.');
      }

      print('📍 ERROR DATA: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  /// Signup/Register
  Future<LoginResponse> signup({
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
      await _prefs?.remove('user_role');
      await _prefs?.remove('event_data');
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

      // Get stored role and merge it with the user data
      final userData = Map<String, dynamic>.from(response.data);
      final storedRole = _prefs?.getString('user_role');
      if (storedRole != null) {
        userData['role'] = storedRole;
      }

      return UserModel.fromJson(userData);
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