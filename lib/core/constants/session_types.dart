// lib/core/constants/session_types.dart

/// Session Type Constants
/// Defines all available session types in the system
class SessionTypes {
  // Session type values (must match backend)
  static const String conference = 'conference';
  static const String atelier = 'atelier';
  static const String communication = 'communication';
  static const String tableRonde = 'table_ronde';
  static const String lunchSymposium = 'lunch_symposium';
  static const String symposium = 'symposium';
  static const String sessionPhotoCommunication = 'session_photo_communication';

  /// Get display name for session type
  static String getDisplayName(String type) {
    switch (type.toLowerCase()) {
      case conference:
        return 'Conférence';
      case atelier:
        return 'Atelier';
      case communication:
        return 'Communication';
      case tableRonde:
        return 'Table Ronde';
      case lunchSymposium:
        return 'Lunch Symposium';
      case symposium:
        return 'Symposium';
      case sessionPhotoCommunication:
        return 'Session Photo de Communication';
      default:
        return type;
    }
  }

  /// Get icon for session type
  static String getIcon(String type) {
    switch (type.toLowerCase()) {
      case conference:
        return '🎤'; // Microphone
      case atelier:
        return '🛠️'; // Tools
      case communication:
        return '💬'; // Speech bubble
      case tableRonde:
        return '🪑'; // Chair (round table)
      case lunchSymposium:
        return '🍽️'; // Dining
      case symposium:
        return '🎓'; // Academic
      case sessionPhotoCommunication:
        return '📸'; // Camera
      default:
        return '📋'; // Clipboard
    }
  }

  /// Check if session type typically requires payment
  static bool isTypicallyPaid(String type) {
    switch (type.toLowerCase()) {
      case atelier:
      case lunchSymposium:
        return true; // Ateliers and lunch symposiums are often paid
      case conference:
      case communication:
      case tableRonde:
      case symposium:
      case sessionPhotoCommunication:
        return false; // Usually free
      default:
        return false;
    }
  }

  /// Get all session types
  static List<String> getAllTypes() {
    return [
      conference,
      atelier,
      communication,
      tableRonde,
      lunchSymposium,
      symposium,
      sessionPhotoCommunication,
    ];
  }

  /// Get all display names
  static List<String> getAllDisplayNames() {
    return getAllTypes().map((type) => getDisplayName(type)).toList();
  }
}
