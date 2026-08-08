// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/user_roles.dart';
import '../data/repositories/room_repository.dart';
import '../data/services/django_api_service.dart';
import '../logic/organizer_room_manager/room_management/room_bloc.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/exhibitor/exhibitor_home_screen.dart';
import '../presentation/screens/exposant/exposant_announcements_screen.dart';
import '../presentation/screens/exposant/exposant_home_screen.dart';
import '../presentation/screens/exposant/exposant_guide_screen.dart';
import '../presentation/screens/exposant/exposant_scanner_screen.dart';
import '../presentation/screens/exposant/exposant_stats_screen.dart';
import '../presentation/screens/organizer_badge_controller/badge_controller_announcements_screen.dart';
import '../presentation/screens/organizer_badge_controller/badge_scanner_screen.dart';
import '../presentation/screens/organizer_badge_controller/organizer_badge_controller_home_screen.dart';
import '../presentation/screens/organizer_badge_controller/program_pdf_screen.dart';
import '../presentation/screens/organizer_badge_controller/statistics_screen.dart';
import '../presentation/screens/organizer_room_manager/announcements_screen.dart';
import '../presentation/screens/organizer_room_manager/organizer_room_manager_home_screen.dart';
import '../presentation/screens/organizer_room_manager/questions_screen.dart';
import '../presentation/screens/organizer_room_manager/room_management/rooms_list_screen.dart';
import '../presentation/screens/participant/eposters_screen.dart';
import '../presentation/screens/participant/guide_screen.dart';
import '../presentation/screens/participant/live_stream_screen.dart';
import '../presentation/screens/participant/participant_announcements_screen.dart';
import '../presentation/screens/participant/participant_home_screen.dart';
import '../presentation/screens/participant/participant_profile_screen.dart';
import '../presentation/screens/participant/program_screen.dart';
import '../presentation/screens/participant/session_detail_screen.dart';
import '../presentation/screens/shared/event_details_screen.dart';
import '../presentation/screens/shared/permission_denied_screen.dart';
import '../presentation/screens/shared/settings/about_screen.dart';
import '../presentation/screens/shared/settings/help_screen.dart';
import '../presentation/screens/shared/settings/privacy_policy_screen.dart';
import '../presentation/screens/shared/settings/profile_settings_screen.dart';
import '../presentation/screens/shared/settings/security_settings_screen.dart';
import '../presentation/screens/shared/settings/terms_of_service_screen.dart';
import '../presentation/screens/shared/settings_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class AppRouter {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Organizer Room Manager routes (Organisateur Gestion des Salles)
  static const String organizerRoomManagerHome = '/organizer-room-manager/home';
  static const String roomsList = '/organizer-room-manager/rooms';
  static const String announcements = '/organizer-room-manager/announcements';
  static const String createAnnouncement =
      '/organizer-room-manager/create-announcement';
  static const String questions = '/organizer-room-manager/questions';
  static const String sessionQuestions =
      '/organizer-room-manager/session-questions';

  // Organizer Badge Controller routes (Organisateur Contrôleur de Badge)
  static const String organizerBadgeControllerHome =
      '/organizer-badge-controller/home';
  static const String badgeControllerAnnouncements =
      '/organizer-badge-controller/announcements';
  static const String badgeScanner =
      '/organizer-badge-controller/badge-scanner';
  static const String scanHistory = '/organizer-badge-controller/scan-history';
  static const String blockedParticipants =
      '/organizer-badge-controller/blocked-participants';
  static const String badgeControllerStats =
      '/organizer-badge-controller/stats';
  static const String badgeControllerProgram =
      '/organizer-badge-controller/program';

  // Participant routes
  static const String participantHome = '/participant/home';
  static const String program = '/participant/program';
  static const String guide = '/participant/guide';
  static const String exhibitors = '/participant/exhibitors';
  static const String sessionDetail = '/participant/session-detail';
  static const String liveStream = '/participant/live-stream';
  static const String eposters = '/participant/eposters';
  static const String participantProfile = '/participant/profile';
  static const String participantAnnouncements = '/participant/announcements';

  // Exhibitor routes
  static const String exhibitorHome = '/exhibitor/home';
  static const String boothPlan = '/exhibitor/booth-plan';
  static const String exhibitorScanner = '/exhibitor/scanner';
  static const String exhibitorStats = '/exhibitor/stats';

  // Exposant routes
  static const String exposantHome = '/exposant/home';
  static const String exposantGuide = '/exposant/guide';
  static const String exposantScanner = '/exposant/scanner';
  static const String exposantStats = '/exposant/stats';
  static const String exposantAnnouncements = '/exposant/announcements';

  // Shared routes
  static const String profile = '/profile';
  static const String eventDetails = '/event-details';
  static const String settings = '/settings';
  static const String profileSettings = '/settings/profile';
  static const String securitySettings = '/settings/security';
  static const String helpSettings = '/settings/help';
  static const String aboutSettings = '/settings/about';
  static const String privacySettings = '/settings/privacy';
  static const String termsSettings = '/settings/terms';
  static const String permissionDenied = '/permission-denied';

  // Get role-based home route
  static String getRoleHomeRoute(String role) {
    // Check for 'exposant' FIRST before isExhibitor()
    // because isExhibitor() also matches 'exposant'
    if (role == 'exposant') {
      return exposantHome;
    } else if (UserRoles.isRoomManager(role)) {
      return organizerRoomManagerHome;
    } else if (UserRoles.isBadgeController(role)) {
      return organizerBadgeControllerHome;
    } else if (UserRoles.isParticipant(role)) {
      return participantHome;
    } else if (UserRoles.isExhibitor(role)) {
      return exhibitorHome;
    } else {
      AppLogger.d('⚠️ Unknown role: $role - defaulting to participant');
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

      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      // Organizer Room Manager routes
      case organizerRoomManagerHome:
        return MaterialPageRoute(
            builder: (_) => const OrganizerRoomManagerHomeScreen());

      case announcements:
        return MaterialPageRoute(builder: (_) => const AnnouncementsScreen());

      case questions:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case sessionQuestions:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => QuestionsScreen(
            sessionId: args?['sessionId'] as String? ?? '',
            sessionTitle: args?['sessionTitle'] as String? ?? 'Session',
          ),
        );

      case roomsList:
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => RoomBloc(
              roomRepository: RoomRepository(
                apiService: context.read<DjangoApiService>(),
              ),
            ),
            child: const RoomsListScreen(),
          ),
        );

      // Participant routes
      case participantHome:
        return MaterialPageRoute(builder: (_) => const ParticipantHomeScreen());

      case sessionDetail:
        final session = settings.arguments as Map<String, dynamic>?;
        if (session == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Session introuvable')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => SessionDetailScreen(session: session),
        );

      case liveStream:
        final streamSession = settings.arguments as Map<String, dynamic>?;
        if (streamSession == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Session introuvable')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => LiveStreamScreen(session: streamSession),
        );

      case eposters:
        return MaterialPageRoute(builder: (_) => const EpostersScreen());

      case participantProfile:
        return MaterialPageRoute(
            builder: (_) => const ParticipantProfileScreen());

      case program:
        return MaterialPageRoute(
            builder: (_) => const ParticipantProgramScreen());

      case guide:
        return MaterialPageRoute(
            builder: (_) => const ParticipantGuideScreen());

      case participantAnnouncements:
        return MaterialPageRoute(
            builder: (_) => const ParticipantAnnouncementsScreen());

      // Organizer Badge Controller routes
      case organizerBadgeControllerHome:
        return MaterialPageRoute(
            builder: (_) => const OrganizerBadgeControllerHomeScreen());

      case badgeControllerAnnouncements:
        return MaterialPageRoute(
            builder: (_) => const BadgeControllerAnnouncementsScreen());

      case badgeControllerStats:
        return MaterialPageRoute(builder: (_) => const StatisticsScreen());

      case badgeControllerProgram:
        return MaterialPageRoute(builder: (_) => const ProgramPdfScreen());

      case badgeScanner:
        return MaterialPageRoute(builder: (_) => const BadgeScannerScreen());

      // Exhibitor routes
      case exhibitorHome:
        return MaterialPageRoute(builder: (_) => const ExhibitorHomeScreen());

      // Exposant routes
      case exposantHome:
        return MaterialPageRoute(builder: (_) => const ExposantHomeScreen());

      case exposantGuide:
        return MaterialPageRoute(builder: (_) => const ExposantGuideScreen());

      case exposantScanner:
        return MaterialPageRoute(builder: (_) => const ExposantScannerScreen());

      case exposantStats:
        return MaterialPageRoute(builder: (_) => const ExposantStatsScreen());

      case exposantAnnouncements:
        return MaterialPageRoute(
            builder: (_) => const ExposantAnnouncementsScreen());

      // Permission denied
      case permissionDenied:
        return MaterialPageRoute(
            builder: (_) => const PermissionDeniedScreen());

      // Event details
      case eventDetails:
        return MaterialPageRoute(builder: (_) => const EventDetailsScreen());

      // Settings routes
      case AppRouter.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case AppRouter.profileSettings:
        return MaterialPageRoute(builder: (_) => const ProfileSettingsScreen());

      case AppRouter.securitySettings:
        return MaterialPageRoute(
            builder: (_) => const SecuritySettingsScreen());

      case AppRouter.helpSettings:
        return MaterialPageRoute(builder: (_) => const HelpScreen());

      case AppRouter.aboutSettings:
        return MaterialPageRoute(builder: (_) => const AboutScreen());

      case AppRouter.privacySettings:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());

      case AppRouter.termsSettings:
        return MaterialPageRoute(builder: (_) => const TermsOfServiceScreen());

      default:
        return MaterialPageRoute(
          builder: (routeContext) => Scaffold(
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
                      Navigator.of(routeContext).pushReplacementNamed(login);
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
