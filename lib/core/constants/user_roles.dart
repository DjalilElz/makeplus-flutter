// lib/core/constants/user_roles.dart

/// User role constants matching database values
class UserRoles {
  // Organisateur Gestion des Salles (Room Manager Organizer)
  static const String organizerRoomManager = 'organisateur_gestion_salles';
  static const String organizerRoomManagerAlt1 =
      'organisateur_gestion_des_salles';
  static const String organizerRoomManagerAlt2 = 'organizer_room_manager';
  static const String organizerRoomManagerAlt3 = 'room_manager';
  static const String organizerRoomManagerAlt4 = 'organizer'; // Legacy support
  static const String organizerRoomManagerAlt5 =
      'organisateur'; // Generic French organizer
  static const String organizerRoomManagerAlt6 =
      'gestionnaire_des_salles'; // Backend v1.1 format

  // Organisateur Contrôleur de Badge (Badge Controller Organizer)
  static const String organizerBadgeController =
      'organisateur_controleur_badge';
  static const String organizerBadgeControllerAlt1 =
      'organisateur_controleur_de_badge';
  static const String organizerBadgeControllerAlt2 =
      'organisateur_controlleur_badge';
  static const String organizerBadgeControllerAlt3 =
      'organizer_badge_controller';
  static const String organizerBadgeControllerAlt4 = 'badge_controller';
  static const String organizerBadgeControllerAlt5 =
      'controller'; // Legacy support
  static const String organizerBadgeControllerAlt6 =
      'controleur'; // French controller
  static const String organizerBadgeControllerAlt7 =
      'contrôleur'; // French with accent
  static const String organizerBadgeControllerAlt8 =
      'controlleur_des_badges'; // French plural with double L
  static const String organizerBadgeControllerAlt9 =
      'controleur_des_badges'; // French plural
  static const String organizerBadgeControllerAlt10 =
      'contrôleur_des_badges'; // French plural with accent

  // Participant
  static const String participant = 'participant';

  // Exposant (Exhibitor)
  static const String exhibitor = 'exposant';
  static const String exhibitorAlt = 'exhibitor'; // Alternative name

  /// Check if role is Room Manager Organizer
  static bool isRoomManager(String role) {
    final normalized = _normalizeRole(role);
    return normalized == _normalizeRole(organizerRoomManager) ||
        normalized == _normalizeRole(organizerRoomManagerAlt1) ||
        normalized == _normalizeRole(organizerRoomManagerAlt2) ||
        normalized == _normalizeRole(organizerRoomManagerAlt3) ||
        normalized == _normalizeRole(organizerRoomManagerAlt4) ||
        normalized == _normalizeRole(organizerRoomManagerAlt5) ||
        normalized == _normalizeRole(organizerRoomManagerAlt6);
  }

  /// Check if role is Badge Controller Organizer
  static bool isBadgeController(String role) {
    final normalized = _normalizeRole(role);
    return normalized == _normalizeRole(organizerBadgeController) ||
        normalized == _normalizeRole(organizerBadgeControllerAlt1) ||
        normalized == _normalizeRole(organizerBadgeControllerAlt2) ||
        normalized == _normalizeRole(organizerBadgeControllerAlt3) ||
        normalized == _normalizeRole(organizerBadgeControllerAlt4) ||
        normalized == _normalizeRole(organizerBadgeControllerAlt5) ||
        normalized == _normalizeRole(organizerBadgeControllerAlt6) ||
        normalized == _normalizeRole(organizerBadgeControllerAlt7) ||
        normalized == _normalizeRole(organizerBadgeControllerAlt8) ||
        normalized == _normalizeRole(organizerBadgeControllerAlt9) ||
        normalized == _normalizeRole(organizerBadgeControllerAlt10);
  }

  /// Check if role is Participant
  static bool isParticipant(String role) {
    return _normalizeRole(role) == _normalizeRole(participant);
  }

  /// Check if role is Exhibitor
  static bool isExhibitor(String role) {
    final normalized = _normalizeRole(role);
    return normalized == _normalizeRole(exhibitor) ||
        normalized == _normalizeRole(exhibitorAlt);
  }

  /// Get user-friendly display name for role
  static String getDisplayName(String role) {
    if (isRoomManager(role)) {
      return 'Organisateur - Gestion des Salles';
    } else if (isBadgeController(role)) {
      return 'Organisateur - Contrôleur de Badge';
    } else if (isParticipant(role)) {
      return 'Participant';
    } else if (isExhibitor(role)) {
      return 'Exposant';
    }
    return role; // Return original if unknown
  }

  /// Normalize role name for comparison
  static String _normalizeRole(String role) {
    return role
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('û', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i');
  }
}
