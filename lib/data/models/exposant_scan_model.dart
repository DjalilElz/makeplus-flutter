/// Exposant Scan Model
/// Tracks when exposants scan participant QR codes (booth visits)
class ExposantScanModel {
  final String id;
  final String exposantId;
  final String scannedParticipantId;
  final String eventId;
  final DateTime scannedAt;
  final String? notes;

  // Optional nested participant details
  final String? participantName;
  final String? participantEmail;
  final String? participantBadge;

  ExposantScanModel({
    required this.id,
    required this.exposantId,
    required this.scannedParticipantId,
    required this.eventId,
    required this.scannedAt,
    this.notes,
    this.participantName,
    this.participantEmail,
    this.participantBadge,
  });

  factory ExposantScanModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to string
    String toString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map && value.containsKey('id')) {
        return value['id'].toString();
      }
      return value.toString();
    }

    // Helper function to extract participant details from nested object or direct fields
    String? getParticipantField(String field) {
      // First check direct field
      if (json[field] != null) {
        return json[field].toString();
      }

      // Then check in nested scanned_participant object
      if (json['scanned_participant'] is Map) {
        final participant = json['scanned_participant'] as Map;

        // Map field names
        if (field == 'participant_name' && participant['name'] != null) {
          return participant['name'].toString();
        }
        if (field == 'participant_email' && participant['email'] != null) {
          return participant['email'].toString();
        }
        if (field == 'participant_badge' && participant['badge_id'] != null) {
          return participant['badge_id'].toString();
        }
      }

      return null;
    }

    return ExposantScanModel(
      id: toString(json['id']),
      exposantId: toString(json['exposant']),
      scannedParticipantId: toString(json['scanned_participant']),
      eventId: toString(json['event']),
      scannedAt: json['scanned_at'] != null
          ? DateTime.parse(json['scanned_at'])
          : DateTime.now(),
      notes: json['notes']?.toString(),
      participantName: getParticipantField('participant_name'),
      participantEmail: getParticipantField('participant_email'),
      participantBadge: getParticipantField('participant_badge'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exposant': exposantId,
      'scanned_participant': scannedParticipantId,
      'event': eventId,
      'scanned_at': scannedAt.toIso8601String(),
      'notes': notes,
      'participant_name': participantName,
      'participant_email': participantEmail,
      'participant_badge': participantBadge,
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(scannedAt);

    if (difference.inDays == 0) {
      // Today
      return 'Aujourd\'hui ${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Hier ${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}';
    } else {
      // Older
      return '${scannedAt.day}/${scannedAt.month}/${scannedAt.year} ${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}';
    }
  }
}
