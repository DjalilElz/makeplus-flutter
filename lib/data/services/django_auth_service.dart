import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  DjangoAuthService() {
    _initPrefs();

    // Add interceptor to remove auth header from public endpoints
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Remove Authorization header for public endpoints
        final publicEndpoints = [
          '/auth/login/',
          '/auth/register/',
          '/auth/password-reset/'
        ];
        if (publicEndpoints
            .any((endpoint) => options.path.contains(endpoint))) {
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

      // Check if user needs to select an event
      final requiresEventSelection =
          response.data['requires_event_selection'] ?? false;

      if (requiresEventSelection == true) {
        // User has multiple events - return response with available events and temp token
        print('🔀 MULTIPLE EVENTS - User needs to select event');

        final tempToken = response.data['temp_token'];
        if (tempToken != null) {
          // Store temp token temporarily
          await _secureStorage.write(key: 'temp_token', value: tempToken);
        }

        // Parse available events
        final availableEventsJson = response.data['available_events'] as List?;
        final availableEvents = availableEventsJson
                ?.map((e) => EventModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        final userData = Map<String, dynamic>.from(response.data['user']);
        final user = UserModel.fromJson(userData);

        return LoginResponse(
          user: user,
          event: null,
          requiresEventSelection: true,
          availableEvents: availableEvents,
        );
      }

      // Single event flow - extract tokens and proceed normally
      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];

      if (accessToken != null) {
        _token = accessToken;
        _dio.options.headers['Authorization'] = 'Bearer $_token';

        // Save to SharedPreferences for backward compatibility
        await _prefs?.setString('auth_token', _token!);

        // Save to FlutterSecureStorage for ApiClient to use
        await _secureStorage.write(key: 'access_token', value: accessToken);
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        print('✅ TOKENS SAVED - Access and Refresh tokens stored');
      }

      // Store user data
      await _prefs?.setString('user_data', response.data['user'].toString());

      // Extract role from current_event object
      String? userRole;
      if (response.data['current_event'] != null &&
          response.data['current_event']['role'] != null) {
        userRole = response.data['current_event']['role'];
        print('🎭 USER ROLE from current_event: $userRole');
      }

      // Store role if available
      if (userRole != null) {
        await _prefs?.setString('user_role', userRole);
      }

      // Parse user and merge with role from API response
      final userData = Map<String, dynamic>.from(response.data['user']);
      // Add the role to the user data
      if (userRole != null) {
        userData['role'] = userRole;
      }

      final user = UserModel.fromJson(userData);
      print('✅ USER MODEL CREATED - Role: ${user.role}');

      // Parse event from current_event
      EventModel? event;
      final eventDataJson = response.data['current_event'];
      if (eventDataJson != null) {
        print('📋 EVENT DATA: $eventDataJson');
        event = EventModel.fromJson(eventDataJson);
        print('🎪 EVENT PARSED - Name: ${event.name}, ID: ${event.id}');
        print('📅 Start: ${event.startDate}, End: ${event.endDate}');
        print('📍 Location: ${event.location}');

        // Store event data for session persistence
        await _prefs?.setString('event_id', event.id);
        await _prefs?.setString('event_name', event.name);
        await _prefs?.setString('event_location', event.location ?? '');
        await _prefs?.setString(
            'event_start_date', event.startDate?.toIso8601String() ?? '');
        await _prefs?.setString(
            'event_end_date', event.endDate?.toIso8601String() ?? '');
        print('💾 EVENT DATA SAVED for session persistence');
      } else {
        print('⚠ NO EVENT DATA IN RESPONSE');
      }

      return LoginResponse(user: user, event: event);
    } on DioException catch (e) {
      print('❌ LOGIN ERROR: ${e.response?.statusCode}');
      print('📍 ERROR TYPE: ${e.type}');
      print('📍 ERROR DATA: ${e.response?.data}');

      // Check if response is HTML (server error)
      if (e.response?.data is String &&
          (e.response?.data as String).contains('<html')) {
        print('⚠️ SERVER ERROR: Backend returned HTML instead of JSON');
        print('💡 This means there\'s an error in your Django backend code');
        throw Exception(
            'Server error: Please check your Django backend logs. The login endpoint is returning an HTML error page instead of JSON.');
      }

      // Handle 500 errors with detail message
      if (e.response?.statusCode == 500) {
        final errorDetail = e.response?.data?['detail'];
        print('🔴 BACKEND ERROR 500: $errorDetail');
        print('💡 Check Django backend logs for the actual error');
        throw Exception(
            'Backend error: $errorDetail\n\nThis is a server-side issue. Please check your Django backend logs.');
      }

      throw _handleError(e);
    }
  }

  /// Select event after login (for users with multiple events)
  Future<LoginResponse> selectEvent(String eventId) async {
    try {
      print('🔵 SELECT EVENT - Selecting event: $eventId');

      // Get temp token from storage
      final tempToken = await _secureStorage.read(key: 'temp_token');
      if (tempToken == null) {
        throw Exception('No temporary token found. Please login again.');
      }

      final response = await _dio.post(
        '/auth/select-event/',
        data: {'event_id': eventId},
        options: Options(
          headers: {'Authorization': 'Bearer $tempToken'},
        ),
      );

      print('✅ SELECT EVENT - Response: ${response.statusCode}');
      print('📦 SELECT EVENT - Data: ${response.data}');

      // Extract tokens from the response
      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];

      if (accessToken != null) {
        _token = accessToken;
        _dio.options.headers['Authorization'] = 'Bearer $_token';

        // Save to SharedPreferences
        await _prefs?.setString('auth_token', _token!);

        // Save to FlutterSecureStorage
        await _secureStorage.write(key: 'access_token', value: accessToken);
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        // Clear temp token
        await _secureStorage.delete(key: 'temp_token');

        print('✅ TOKENS SAVED - Access and Refresh tokens stored');
      }

      // Extract role from current_event
      String? userRole;
      if (response.data['current_event'] != null &&
          response.data['current_event']['role'] != null) {
        userRole = response.data['current_event']['role'];
        print('🎭 USER ROLE: $userRole');
        if (userRole != null) {
          await _prefs?.setString('user_role', userRole);
        }
      }

      // Parse user and merge with role
      final userData = Map<String, dynamic>.from(response.data['user']);
      if (userRole != null) {
        userData['role'] = userRole;
      }

      final user = UserModel.fromJson(userData);
      print('✅ USER MODEL CREATED - Role: ${user.role}');

      // Parse event from current_event
      EventModel? event;
      final eventDataJson = response.data['current_event'];
      if (eventDataJson != null) {
        event = EventModel.fromJson(eventDataJson);
        print('🎪 EVENT SELECTED - Name: ${event.name}, ID: ${event.id}');

        // Store event data for session persistence
        await _prefs?.setString('event_id', event.id);
        await _prefs?.setString('event_name', event.name);
        await _prefs?.setString('event_location', event.location ?? '');
        await _prefs?.setString(
            'event_start_date', event.startDate?.toIso8601String() ?? '');
        await _prefs?.setString(
            'event_end_date', event.endDate?.toIso8601String() ?? '');
      }

      return LoginResponse(user: user, event: event);
    } on DioException catch (e) {
      print('❌ SELECT EVENT ERROR: ${e.response?.statusCode}');
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
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

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

      // Clear SharedPreferences
      await _prefs?.remove('auth_token');
      await _prefs?.remove('user_data');
      await _prefs?.remove('user_role');
      await _prefs?.remove('event_id');
      await _prefs?.remove('event_name');
      await _prefs?.remove('event_location');
      await _prefs?.remove('event_start_date');
      await _prefs?.remove('event_end_date');

      // Clear FlutterSecureStorage
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');

      print('✅ LOGOUT - All tokens cleared');
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

  /// Get current user with event data (for session restoration)
  Future<LoginResponse?> getCurrentUserWithEvent() async {
    if (_token == null) {
      print('⚠️ No token found');
      return null;
    }

    try {
      final response = await _dio.get('/auth/me/');

      print('📦 GET USER RESPONSE: ${response.data}');

      // Get stored role and merge it with the user data
      final userData = Map<String, dynamic>.from(response.data);
      final storedRole = _prefs?.getString('user_role');
      if (storedRole != null) {
        userData['role'] = storedRole;
      }

      final user = UserModel.fromJson(userData);

      // Try to get event data from API response first (assignments array)
      EventModel? event;
      if (response.data['assignments'] != null &&
          (response.data['assignments'] as List).isNotEmpty) {
        final assignment = (response.data['assignments'] as List).first;
        final eventId = assignment['event_id'];
        final eventName = assignment['event_name'];
        final eventLocation = assignment['event_location'];
        final eventStartDate = assignment['event_start_date'];
        final eventEndDate = assignment['event_end_date'];

        if (eventId != null && eventName != null) {
          // Create event model from assignment data with all available fields
          event = EventModel(
            id: eventId,
            name: eventName,
            location: eventLocation,
            startDate:
                eventStartDate != null ? DateTime.parse(eventStartDate) : null,
            endDate: eventEndDate != null ? DateTime.parse(eventEndDate) : null,
          );

          // Store for next session
          await _prefs?.setString('event_id', eventId);
          await _prefs?.setString('event_name', eventName);
          await _prefs?.setString('event_location', eventLocation ?? '');
          await _prefs?.setString(
              'event_start_date', event.startDate?.toIso8601String() ?? '');
          await _prefs?.setString(
              'event_end_date', event.endDate?.toIso8601String() ?? '');
          print('🎪 EVENT FROM ASSIGNMENTS - ${event.name}');
          print('📅 Start: ${event.startDate}, End: ${event.endDate}');
          print('📍 Location: ${event.location}');
        }
      }

      // Fallback to stored event data if not in API response
      if (event == null) {
        final eventId = _prefs?.getString('event_id');
        final eventName = _prefs?.getString('event_name');

        if (eventId != null && eventName != null) {
          event = EventModel(
            id: eventId,
            name: eventName,
            location: _prefs?.getString('event_location'),
            startDate: _prefs?.getString('event_start_date') != null &&
                    _prefs!.getString('event_start_date')!.isNotEmpty
                ? DateTime.parse(_prefs!.getString('event_start_date')!)
                : null,
            endDate: _prefs?.getString('event_end_date') != null &&
                    _prefs!.getString('event_end_date')!.isNotEmpty
                ? DateTime.parse(_prefs!.getString('event_end_date')!)
                : null,
          );
          print('💾 EVENT FROM STORAGE - ${event.name}');
        }
      }

      return LoginResponse(user: user, event: event);
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
