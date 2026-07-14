// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/user_roles.dart';
import '../data/repositories/room_repository.dart';
import '../data/services/django_api_service.dart';
import '../logic/organizer_room_manager/room_management/room_bloc.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/exhibitor/exhibitor_home_screen.dart';
import '../presentation/screens/exposant/exposant_announcements_screen.dart';
import '../presentation/screens/exposant/exposant_home_screen.dart';
import '../presentation/screens/exposant/exposant_plan_screen.dart';
import '../presentation/screens/exposant/exposant_scanner_screen.dart';
import '../presentation/screens/exposant/exposant_stats_screen.dart';
import '../presentation/screens/exposant/participant_info_screen.dart';
import '../presentation/screens/organizer_badge_controller/badge_controller_announcements_screen.dart';
import '../presentation/screens/organizer_badge_controller/badge_scanner_screen.dart';
import '../presentation/screens/organizer_badge_controller/organizer_badge_controller_home_screen.dart';
import '../presentation/screens/organizer_badge_controller/program_pdf_screen.dart';
import '../presentation/screens/organizer_badge_controller/statistics_screen.dart';
import '../presentation/screens/organizer_room_manager/announcements_screen.dart';
import '../presentation/screens/organizer_room_manager/organizer_room_manager_home_screen.dart';
import '../presentation/screens/organizer_room_manager/participants_list_screen.dart';
import '../presentation/screens/organizer_room_manager/room_management/room_detail_screen.dart';
import '../presentation/screens/organizer_room_manager/room_management/rooms_list_screen.dart';
import '../presentation/screens/participant/diffusion_screen.dart';
import '../presentation/screens/participant/eposters_screen.dart';
import '../presentation/screens/participant/guide_screen.dart';
import '../presentation/screens/participant/live_stream_screen.dart';
import '../presentation/screens/participant/participant_announcements_screen.dart';
import '../presentation/screens/participant/participant_home_screen.dart';
import '../presentation/screens/participant/participant_profile_screen.dart';
import '../presentation/screens/participant/qr_badge/my_badge_screen.dart';
import '../presentation/screens/participant/program_screen.dart';
import '../presentation/screens/participant/session_detail_screen.dart';
import '../presentation/screens/shared/event_details_screen.dart';
import '../presentation/screens/shared/permission_denied_screen.dart';
import '../presentation/screens/shared/settings/generic_settings_screen.dart';
import '../presentation/screens/shared/settings/notification_settings_screen.dart';
import '../presentation/screens/shared/settings/profile_settings_screen.dart';
import '../presentation/screens/shared/settings/security_settings_screen.dart';
import '../presentation/screens/shared/settings_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class AppRouter {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';

  // Organizer Room Manager routes (Organisateur Gestion des Salles)
  static const String organizerRoomManagerHome = '/organizer-room-manager/home';
  static const String participantsList = '/organizer-room-manager/participants';
  static const String roomsList = '/organizer-room-manager/rooms';
  static const String roomDetail = '/organizer-room-manager/room-detail';
  static const String addSession = '/organizer-room-manager/add-session';
  static const String announcements = '/organizer-room-manager/announcements';
  static const String createAnnouncement =
      '/organizer-room-manager/create-announcement';
  static const String questions = '/organizer-room-manager/questions';

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
  static const String myBadge = '/participant/my-badge';
  static const String guide = '/participant/guide';
  static const String exhibitors = '/participant/exhibitors';
  static const String diffusion = '/participant/diffusion';
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
  static const String exposantParticipantInfo = '/exposant/participant-info';

  // Shared routes
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String eventDetails = '/event-details';
  static const String settings = '/settings';
  static const String profileSettings = '/settings/profile';
  static const String securitySettings = '/settings/security';
  static const String notificationSettings = '/settings/notifications';
  static const String languageSettings = '/settings/language';
  static const String appearanceSettings = '/settings/appearance';
  static const String helpSettings = '/settings/help';
  static const String aboutSettings = '/settings/about';
  static const String privacySettings = '/settings/privacy';
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

      // Organizer Room Manager routes
      case organizerRoomManagerHome:
        return MaterialPageRoute(
            builder: (_) => const OrganizerRoomManagerHomeScreen());

      case participantsList:
        return MaterialPageRoute(
            builder: (_) => const ParticipantsListScreen());

      case announcements:
        return MaterialPageRoute(builder: (_) => const AnnouncementsScreen());

      case questions:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

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

      case roomDetail:
        final roomId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => RoomDetailScreen(roomId: roomId ?? ''),
        );

      // Participant routes
      case participantHome:
        return MaterialPageRoute(builder: (_) => const ParticipantHomeScreen());

      case diffusion:
        return MaterialPageRoute(builder: (_) => const DiffusionScreen());

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

      case myBadge:
        return MaterialPageRoute(builder: (_) => const MyBadgeScreen());

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
        return MaterialPageRoute(builder: (_) => const ExposantPlanScreen());

      case exposantScanner:
        return MaterialPageRoute(builder: (_) => const ExposantScannerScreen());

      case exposantStats:
        return MaterialPageRoute(builder: (_) => const ExposantStatsScreen());

      case exposantAnnouncements:
        return MaterialPageRoute(
            builder: (_) => const ExposantAnnouncementsScreen());

      case exposantParticipantInfo:
        final scannedCode = settings.arguments as String?;
        if (scannedCode == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Code invalide')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ParticipantInfoScreen(scannedData: scannedCode),
        );

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

      case AppRouter.notificationSettings:
        return MaterialPageRoute(
            builder: (_) => const NotificationSettingsScreen());

      case AppRouter.languageSettings:
        return MaterialPageRoute(
          builder: (_) => const GenericSettingsScreen(
            title: 'Langue',
            content:
                'Choisissez votre langue préférée:\n\n• Français\n• العربية\n• English\n\nLa langue sera mise à jour prochainement.',
          ),
        );

      case AppRouter.appearanceSettings:
        return MaterialPageRoute(
          builder: (_) => const GenericSettingsScreen(
            title: 'Apparence',
            content:
                'Personnalisez l\'apparence de l\'application:\n\n• Thème clair\n• Thème sombre\n• Automatique\n\nCette fonctionnalité sera disponible bientôt.',
          ),
        );

      case AppRouter.helpSettings:
        return MaterialPageRoute(
          builder: (_) => const GenericSettingsScreen(
            title: 'Aide',
            content:
                'Questions fréquentes:\n\n1. Comment accéder aux sessions?\n2. Comment utiliser le scanner de badge?\n3. Comment contacter le support?\n\nPour plus d\'aide, contactez support@makeplus.com',
          ),
        );

      case AppRouter.aboutSettings:
        return MaterialPageRoute(
          builder: (_) => const GenericSettingsScreen(
            title: 'À propos',
            content:
                'MakePlus Event App\n\nVersion: 1.0.0\nBuild: 100\n\n© 2025 MakePlus. Tous droits réservés.\n\nDéveloppé avec ❤️ en Algérie',
          ),
        );

      case AppRouter.privacySettings:
        return MaterialPageRoute(
          builder: (_) => const GenericSettingsScreen(
            title: 'Confidentialité',
            content:
                'Politique de confidentialité\n\nVos données personnelles sont protégées conformément aux lois en vigueur.\n\nNous collectons uniquement les données nécessaires au bon fonctionnement de l\'application.\n\nPour plus d\'informations, consultez notre politique complète sur makeplus.com/privacy',
          ),
        );

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
