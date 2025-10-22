// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/organizer/orgniser_home_screen.dart';
import '../presentation/screens/organizer/room_management/rooms_list_screen.dart';
import '../presentation/screens/organizer/room_management/room_detail_screen.dart';
import '../presentation/screens/shared/permission_denied_screen.dart';

class AppRouter {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  
  // Organizer routes
  static const String organizerHome = '/organizer/home';
  static const String roomsList = '/organizer/rooms';
  static const String roomDetail = '/organizer/room-detail';
  static const String addSession = '/organizer/add-session';
  static const String announcements = '/organizer/announcements';
  static const String createAnnouncement = '/organizer/create-announcement';
  
  // Controller routes
  static const String controllerHome = '/controller/home';
  static const String badgeScanner = '/controller/badge-scanner';
  static const String controllerStats = '/controller/stats';
  
  // Participant routes
  static const String participantHome = '/participant/home';
  static const String program = '/participant/program';
  static const String myBadge = '/participant/my-badge';
  static const String guide = '/participant/guide';
  static const String exhibitors = '/participant/exhibitors';
  
  // Exhibitor routes
  static const String exhibitorHome = '/exhibitor/home';
  static const String boothPlan = '/exhibitor/booth-plan';
  static const String exhibitorScanner = '/exhibitor/scanner';
  static const String exhibitorStats = '/exhibitor/stats';
  
  // Shared routes
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String permissionDenied = '/permission-denied';

  // Get role-based home route
  static String getRoleHomeRoute(String role) {
    switch (role.toLowerCase()) {
      case 'organizer':
        return organizerHome;
      case 'controller':
        return controllerHome;
      case 'participant':
        return participantHome;
      case 'exhibitor':
        return exhibitorHome;
      default:
        return participantHome;
    }
  }

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      // Organizer routes
      case organizerHome:
        return MaterialPageRoute(builder: (_) => const OrganizerHomeScreen());
      
      case roomsList:
        return MaterialPageRoute(builder: (_) => const RoomsListScreen());
      
      case roomDetail:
        final roomId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => RoomDetailScreen(roomId: roomId ?? ''),
        );
      
      // Permission denied
      case permissionDenied:
        return MaterialPageRoute(builder: (_) => const PermissionDeniedScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No route defined for ${settings.name}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(_).pushReplacementNamed(login);
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}