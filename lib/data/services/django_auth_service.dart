import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:makeplus/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'package:makeplus/core/utils/app_logger.dart';
import 'page_cache_service.dart';

String? _emptyToNull(String? value) =>
    (value == null || value.isEmpty) ? null : value;

class DjangoAuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  String? _token;
  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final Future<void> _initFuture;

  DjangoAuthService() {
    _initFuture = _initPrefs();

    // Longer connection timeout: Render cold starts + slow DNS on mobile networks.
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);
      return client;
    };

    // Add interceptor to remove auth header from public endpoints
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Remove Authorization header for public endpoints
        final publicEndpoints = [
          '/auth/token/',
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

    // Debug only: this logs Authorization headers and login payloads.
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
      ));
    }
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    // The access token itself only ever lives in secure storage -- never
    // in SharedPreferences, which is unencrypted plaintext on disk.
    _token = await _secureStorage.read(key: 'access_token');
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  /// Login with email and password
  Future<LoginResponse> login(String email, String password) async {
    try {
      AppLogger.d('🔵 LOGIN - Starting login for: $email');

      final response = await _postWithDnsFallback(
        '/auth/token/',
        data: {
          'email': email,
          'password': password,
        },
      );

      AppLogger.d('✅ LOGIN - Response: ${response.statusCode}');
      AppLogger.d('📦 LOGIN - Data: ${response.data}');

      // Check if user needs to select an event
      final requiresEventSelection =
          response.data['requires_event_selection'] ?? false;

      if (requiresEventSelection == true) {
        // User has multiple events - return response with available events and temp token
        AppLogger.d('🔀 MULTIPLE EVENTS - User needs to select event');

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

        // Save to FlutterSecureStorage (encrypted) for ApiClient to use
        await _secureStorage.write(key: 'access_token', value: accessToken);
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        AppLogger.d('✅ TOKENS SAVED - Access and Refresh tokens stored');
      }

      // Store user data
      await _prefs?.setString('user_data', response.data['user'].toString());

      // Extract role from response (new API: top-level role, legacy: current_event.role)
      String? userRole;
      userRole = response.data['role'] as String?;
      userRole ??= response.data['current_event']?['role'] as String?;
      userRole ??= response.data['event']?['role'] as String?;
      if (userRole != null) {
        AppLogger.d('🎭 USER ROLE: $userRole');
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
      // qr_code arrives top-level but belongs on the user: it is the badge payload
      // scanners validate against. Dropping it forces the UI to invent a fake one.
      userData['qr_code'] = response.data['qr_code'];

      final user = UserModel.fromJson(userData);
      AppLogger.d('✅ USER MODEL CREATED - Role: ${user.role}');

      // Parse event from response (new API: event, legacy: current_event)
      EventModel? event;
      final eventDataJson =
          response.data['event'] ?? response.data['current_event'];
      if (eventDataJson != null) {
        AppLogger.d('📋 EVENT DATA: $eventDataJson');
        event = EventModel.fromJson(eventDataJson);
        AppLogger.d('🎪 EVENT PARSED - Name: ${event.name}, ID: ${event.id}');
        AppLogger.d('📅 Start: ${event.startDate}, End: ${event.endDate}');
        AppLogger.d('📍 Location: ${event.location}');

        // Store event data for session persistence
        await _prefs?.setString('event_id', event.id);
        await _prefs?.setString('event_name', event.name);
        await _prefs?.setString('event_location', event.location ?? '');
        await _prefs?.setString(
            'event_start_date', event.startDate?.toIso8601String() ?? '');
        await _prefs?.setString(
            'event_end_date', event.endDate?.toIso8601String() ?? '');
        await _prefs?.setString('event_description', event.description ?? '');
        await _prefs?.setString('event_logo', event.logoUrl ?? '');
        await _prefs?.setString('event_banner', event.bannerUrl ?? '');
        await _prefs?.setString(
            'event_primary_color',
            event.primaryColor != null
                ? '#${event.primaryColor!.toARGB32().toRadixString(16).substring(2)}'
                : '');
        AppLogger.d('💾 EVENT DATA SAVED for session persistence');
      } else {
        AppLogger.d('⚠ NO EVENT DATA IN RESPONSE');
      }

      return LoginResponse(user: user, event: event);
    } on DioException catch (e) {
      AppLogger.d('❌ LOGIN ERROR: ${e.response?.statusCode}');
      AppLogger.d('📍 ERROR TYPE: ${e.type}');
      AppLogger.d('📍 ERROR DATA: ${e.response?.data}');

      // Check if response is HTML (server error)
      if (e.response?.data is String &&
          (e.response?.data as String).contains('<html')) {
        AppLogger.d('⚠️ SERVER ERROR: Backend returned HTML instead of JSON');
        AppLogger.d(
            '💡 This means there\'s an error in your Django backend code');
        throw Exception(
            'Server error: Please check your Django backend logs. The login endpoint is returning an HTML error page instead of JSON.');
      }

      // Handle 500 errors with detail message
      if (e.response?.statusCode == 500) {
        final errorDetail = e.response?.data?['detail'];
        AppLogger.d('🔴 BACKEND ERROR 500: $errorDetail');
        AppLogger.d('💡 Check Django backend logs for the actual error');
        throw Exception(
            'Backend error: $errorDetail\n\nThis is a server-side issue. Please check your Django backend logs.');
      }

      throw _handleError(e);
    }
  }

  Future<Response<dynamic>> _postWithDnsFallback(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.post(path, data: data, options: options);
    } on DioException catch (e) {
      // Check if this is a DNS/connection error and we haven't tried fallback yet
      final isDnsError = e.type == DioExceptionType.connectionError &&
          e.message?.contains('Failed host lookup') == true;

      final canFallback =
          isDnsError && _dio.options.baseUrl != ApiConstants.fallbackBaseUrl;

      if (!canFallback) {
        // If fallback also failed or not a DNS error, provide helpful message
        if (isDnsError) {
          AppLogger.d(
              '❌ DNS RESOLUTION FAILED for both primary and fallback URLs');
          AppLogger.d('💡 Your device cannot resolve .onrender.com domains');
          AppLogger.d('💡 Possible solutions:');
          AppLogger.d('   1. Check your internet connection');
          AppLogger.d('   2. Try switching between WiFi and mobile data');
          AppLogger.d('   3. Disable Private DNS in Android settings');
          AppLogger.d('   4. Change DNS to 8.8.8.8 in WiFi settings');
          AppLogger.d('   5. Contact your network administrator');
        }
        rethrow;
      }

      AppLogger.d(
          '🌐 DNS fallback: retrying against ${ApiConstants.fallbackBaseUrl}');
      _dio.options.baseUrl = ApiConstants.fallbackBaseUrl;
      return await _dio.post(path, data: data, options: options);
    }
  }

  /// Select event after login (for users with multiple events)
  Future<LoginResponse> selectEvent(String eventId) async {
    try {
      AppLogger.d('🔵 SELECT EVENT - Selecting event: $eventId');

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

      AppLogger.d('✅ SELECT EVENT - Response: ${response.statusCode}');
      AppLogger.d('📦 SELECT EVENT - Data: ${response.data}');

      // Extract tokens from the response
      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];

      if (accessToken != null) {
        _token = accessToken;
        _dio.options.headers['Authorization'] = 'Bearer $_token';

        // Save to FlutterSecureStorage (encrypted)
        await _secureStorage.write(key: 'access_token', value: accessToken);
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        // Clear temp token
        await _secureStorage.delete(key: 'temp_token');

        AppLogger.d('✅ TOKENS SAVED - Access and Refresh tokens stored');
      }

      // Extract role from response (new API: top-level role, legacy: current_event.role)
      String? userRole;
      userRole = response.data['role'] as String?;
      userRole ??= response.data['current_event']?['role'] as String?;
      userRole ??= response.data['event']?['role'] as String?;
      if (userRole != null) {
        AppLogger.d('🎭 USER ROLE: $userRole');
        await _prefs?.setString('user_role', userRole);
      }

      // Parse user and merge with role
      final userData = Map<String, dynamic>.from(response.data['user']);
      if (userRole != null) {
        userData['role'] = userRole;
      }
      userData['qr_code'] = response.data['qr_code'];

      final user = UserModel.fromJson(userData);
      AppLogger.d('✅ USER MODEL CREATED - Role: ${user.role}');

      // Parse event from response (new API: event, legacy: current_event)
      EventModel? event;
      final eventDataJson =
          response.data['event'] ?? response.data['current_event'];
      if (eventDataJson != null) {
        event = EventModel.fromJson(eventDataJson);
        AppLogger.d('🎪 EVENT SELECTED - Name: ${event.name}, ID: ${event.id}');

        // Store event data for session persistence
        await _prefs?.setString('event_id', event.id);
        await _prefs?.setString('event_name', event.name);
        await _prefs?.setString('event_location', event.location ?? '');
        await _prefs?.setString(
            'event_start_date', event.startDate?.toIso8601String() ?? '');
        await _prefs?.setString(
            'event_end_date', event.endDate?.toIso8601String() ?? '');
        await _prefs?.setString('event_description', event.description ?? '');
        await _prefs?.setString('event_logo', event.logoUrl ?? '');
        await _prefs?.setString('event_banner', event.bannerUrl ?? '');
        await _prefs?.setString(
            'event_primary_color',
            event.primaryColor != null
                ? '#${event.primaryColor!.toARGB32().toRadixString(16).substring(2)}'
                : '');
      }

      return LoginResponse(user: user, event: event);
    } on DioException catch (e) {
      AppLogger.d('❌ SELECT EVENT ERROR: ${e.response?.statusCode}');
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
      AppLogger.d('🔵 SIGNUP - Starting signup for: $email');

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

      AppLogger.d('✅ SIGNUP - Success: ${response.statusCode}');

      // Auto-login after signup
      return await login(email, password);
    } on DioException catch (e) {
      AppLogger.d('❌ SIGNUP ERROR: ${e.response?.statusCode}');
      throw _handleError(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout/');
    } catch (e) {
      AppLogger.d('⚠️ Logout error (ignored): $e');
    } finally {
      _token = null;
      _dio.options.headers.remove('Authorization');

      // Clear SharedPreferences
      await _prefs?.remove('user_data');
      await _prefs?.remove('user_role');
      await _prefs?.remove('event_id');
      await _prefs?.remove('event_name');
      await _prefs?.remove('event_location');
      await _prefs?.remove('event_start_date');
      await _prefs?.remove('event_end_date');
      await _prefs?.remove('event_description');
      await _prefs?.remove('event_logo');
      await _prefs?.remove('event_banner');
      await _prefs?.remove('event_primary_color');

      // Clear FlutterSecureStorage
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');

      // Clear cached page data so the next account never sees a flash of
      // this one's content.
      PageCacheService.instance.clear();

      AppLogger.d('✅ LOGOUT - All tokens cleared');
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    await _initFuture;
    if (_token == null) {
      AppLogger.d('⚠️ No token found');
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
      AppLogger.d('❌ GET USER ERROR: ${e.response?.statusCode}');
      if (e.response?.statusCode == 401) {
        await logout();
      }
      return null;
    }
  }

  /// Get current user with event data (for session restoration)
  Future<LoginResponse?> getCurrentUserWithEvent() async {
    await _initFuture;
    if (_token == null) {
      AppLogger.d('⚠️ No token found');
      return null;
    }

    try {
      final response = await _dio.get('/auth/me/');

      AppLogger.d('📦 GET USER RESPONSE: ${response.data}');

      // Get stored role and merge it with the user data
      final userData = Map<String, dynamic>.from(response.data);
      final storedRole = _prefs?.getString('user_role');
      if (storedRole != null) {
        userData['role'] = storedRole;
      }

      final user = UserModel.fromJson(userData);

      // Get event data from the API response's `event` object (the shape
      // /auth/me/ actually returns) -- parsed through EventModel.fromJson
      // like login() does, so every field (including programme_file/
      // guide_file/primary_color) comes through consistently instead of
      // being hand-picked field-by-field.
      EventModel? event;
      final eventDataJson = response.data['event'];
      if (eventDataJson != null) {
        event = EventModel.fromJson(eventDataJson as Map<String, dynamic>);

        // Store for next session (fallback below, if this endpoint or the
        // network is ever unreachable on a later app start)
        await _prefs?.setString('event_id', event.id);
        await _prefs?.setString('event_name', event.name);
        await _prefs?.setString('event_location', event.location ?? '');
        await _prefs?.setString(
            'event_start_date', event.startDate?.toIso8601String() ?? '');
        await _prefs?.setString(
            'event_end_date', event.endDate?.toIso8601String() ?? '');
        await _prefs?.setString('event_description', event.description ?? '');
        await _prefs?.setString('event_logo', event.logoUrl ?? '');
        await _prefs?.setString('event_banner', event.bannerUrl ?? '');
        await _prefs?.setString(
            'event_primary_color',
            event.primaryColor != null
                ? '#${event.primaryColor!.toARGB32().toRadixString(16).substring(2)}'
                : '');
        AppLogger.d('🎪 EVENT FROM /auth/me/ - ${event.name}');
        AppLogger.d('📅 Start: ${event.startDate}, End: ${event.endDate}');
        AppLogger.d('📍 Location: ${event.location}');
        AppLogger.d(
            '📄 Programme: ${event.programmeFile}, Guide: ${event.guideFile}');
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
            description: _emptyToNull(_prefs?.getString('event_description')),
            logoUrl: _emptyToNull(_prefs?.getString('event_logo')),
            bannerUrl: _emptyToNull(_prefs?.getString('event_banner')),
            primaryColor: EventModel.parseHexColor(
                _emptyToNull(_prefs?.getString('event_primary_color'))),
          );
          AppLogger.d('💾 EVENT FROM STORAGE - ${event.name}');
        }
      }

      return LoginResponse(user: user, event: event);
    } on DioException catch (e) {
      AppLogger.d('❌ GET USER ERROR: ${e.response?.statusCode}');
      if (e.response?.statusCode == 401) {
        await logout();
      }
      return null;
    }
  }

  /// Update the user's display name. Email is deliberately not editable
  /// here -- login authenticates with username=email server-side, so
  /// changing email would need to stay in lockstep with username; the
  /// backend doesn't support that yet, see UserProfileAPIView.patch.
  Future<UserModel?> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    try {
      await _dio.patch(
        '/auth/me/',
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );
      // Re-fetch rather than reconstruct UserModel from the PATCH response,
      // so role/qr_code/event come back merged exactly like every other
      // read of this endpoint.
      return getCurrentUser();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete (deactivate + anonymize) the current account. See
  /// UserProfileAPIView.delete on the backend for why this isn't a hard
  /// delete. Requires the current password as re-confirmation.
  Future<void> deleteAccount({required String password}) async {
    try {
      await _dio.delete(
        '/auth/me/',
        data: {'password': password},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Data portability: everything this app collects about the current
  /// user, as a JSON map. See UserDataExportAPIView on the backend.
  Future<Map<String, dynamic>> exportData() async {
    try {
      final response = await _dio.get('/auth/me/export/');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _handleError(e);
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

    // Handle DNS/connection errors
    if (e.type == DioExceptionType.connectionError) {
      if (e.message?.contains('Failed host lookup') == true) {
        return 'Cannot reach server. Please check:\n'
            '1. Your internet connection\n'
            '2. If using emulator, try a real device\n'
            '3. Backend server is running and accessible';
      }
      return 'Connection failed. Please check your internet connection.';
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
