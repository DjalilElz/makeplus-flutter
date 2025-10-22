/// API Constants
/// Contains all API endpoints and configuration
class ApiConstants {
  // Base URL - Update this with your actual backend URL
  static const String baseUrl = 'https://makeplus-django-5.onrender.com/api';
  
  // Authentication Endpoints
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String logout = '/auth/logout/';
  static const String tokenRefresh = '/auth/token/refresh/';
  static const String tokenVerify = '/auth/token/verify/';
  static const String profile = '/auth/profile/';
  static const String changePassword = '/auth/change-password/';
  
  // Event Endpoints
  static const String events = '/events/';
  static String eventDetail(String id) => '/events/$id/';
  static String eventStatistics(String id) => '/events/$id/statistics/';
  static String eventSessions(String id) => '/events/$id/sessions/';
  static String eventParticipants(String id) => '/events/$id/participants/';
  
  // Room Endpoints
  static const String rooms = '/rooms/';
  static String roomDetail(String id) => '/rooms/$id/';
  static String roomSessions(String id) => '/rooms/$id/sessions/';
  static String roomCurrentSession(String id) => '/rooms/$id/current_session/';
  
  // Session Endpoints
  static const String sessions = '/sessions/';
  static String sessionDetail(String id) => '/sessions/$id/';
  static String sessionStart(String id) => '/sessions/$id/start/';
  static String sessionEnd(String id) => '/sessions/$id/end/';
  static String sessionLive = '/sessions/live/';
  
  // Participant Endpoints
  static const String participants = '/participants/';
  static String participantDetail(String id) => '/participants/$id/';
  static String participantCheckIn(String id) => '/participants/$id/check_in/';
  
  // Room Access Endpoints
  static const String roomAccess = '/room-access/';
  static String roomAccessDetail(String id) => '/room-access/$id/';
  
  // User Event Assignment Endpoints
  static const String userAssignments = '/user-assignments/';
  static String userAssignmentDetail(String id) => '/user-assignments/$id/';
  
  // QR Code Endpoints
  static const String qrVerify = '/qr/verify/';
  static const String qrGenerate = '/qr/generate/';
  
  // Dashboard & Statistics
  static const String dashboardStats = '/dashboard/stats/';
  
  // Notification Endpoints
  static const String notifications = '/notifications/';
  static String notificationDetail(String id) => '/notifications/$id/';
  static String notificationRead(String id) => '/notifications/$id/read/';
  
  // Timeout configurations
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}