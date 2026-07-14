/// API Constants
/// Contains all API endpoints and configuration
class ApiConstants {
  /// Production default. Override per-build with:
  ///   flutter run --dart-define=API_BASE_URL=https://staging.example.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://makeplus-events.onrender.com/api',
  );

  // Fallback endpoint (same host - no internal Render domain exists)
  static const String fallbackBaseUrl = baseUrl;

  // ==================== AUTHENTICATION ENDPOINTS ====================
  static const String login = '/auth/login/'; // Passwordless login with code
  static const String tokenLogin =
      '/auth/token/'; // JWT login with email/password
  static const String tokenRefresh = '/auth/token/refresh/';
  static const String tokenVerify = '/auth/token/verify/';
  static const String profile = '/auth/me/';

  // NOTE: These endpoints are NOT available per backend specification
  // static const String register = '/auth/register/'; // ❌ NOT AVAILABLE
  // static const String logout = '/auth/logout/'; // ❌ NOT AVAILABLE
  // static const String changePassword = '/auth/change-password/'; // ❌ NOT AVAILABLE

  // ==================== EVENT ENDPOINTS ====================
  static const String events = '/events/';
  static String eventDetail(String id) => '/events/$id/';
  static String eventStatistics(String id) => '/events/$id/statistics/';

  // ==================== ROOM ENDPOINTS ====================
  static const String rooms = '/rooms/';
  static String roomDetail(String id) => '/rooms/$id/';
  static String roomVerifyAccess(String id) => '/rooms/$id/verify_access/';

  // ==================== SESSION ENDPOINTS ====================
  static const String sessions = '/sessions/';
  static String sessionDetail(String id) => '/sessions/$id/';
  static String sessionStart(String id) => '/sessions/$id/start/';
  static String sessionEnd(String id) => '/sessions/$id/end/';

  // ==================== PARTICIPANT ENDPOINTS ====================
  static const String participants = '/participants/';
  static String participantDetail(String id) => '/participants/$id/';

  // ==================== ROOM ACCESS ENDPOINTS ====================
  static const String roomAccess = '/room-access/';
  static String roomAccessDetail(String id) => '/room-access/$id/';

  // ==================== SESSION ACCESS (PAID SESSIONS) ENDPOINTS ====================
  static const String sessionAccess = '/session-access/';
  static String sessionAccessDetail(String id) => '/session-access/$id/';

  // ==================== QR CODE ENDPOINTS ====================
  static const String qrVerify = '/qr/verify/';
  static const String qrGenerate = '/qr/generate/';

  // ==================== EXPOSANT SCAN ENDPOINTS ====================
  static const String exposantScans = '/exposant-scans/';
  static String exposantScanDetail(String id) => '/exposant-scans/$id/';

  // ==================== NOTIFICATION ENDPOINTS ====================
  // NOTE: Notifications are not in the mobile spec, keeping for future use
  static const String notifications = '/notifications/';
  static String notificationDetail(String id) => '/notifications/$id/';
  static String notificationRead(String id) => '/notifications/$id/read/';

  // ==================== DASHBOARD & STATISTICS ====================
  // NOTE: Dashboard stats not in mobile spec, keeping for future use
  static const String dashboardStats = '/dashboard/stats/';

  // Timeout configurations
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
