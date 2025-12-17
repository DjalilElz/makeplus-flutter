/// Participant Model
/// Represents a participant profile with badge information
class ParticipantModel {
  final String id;
  final int userId;
  final String eventId;
  final String badgeNumber;
  final String qrCodeData;
  final DateTime registrationDate;
  final String? planFile;

  // User details (from nested user object)
  final String? firstName;
  final String? lastName;
  final String? email;

  ParticipantModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.badgeNumber,
    required this.qrCodeData,
    required this.registrationDate,
    this.planFile,
    this.firstName,
    this.lastName,
    this.email,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'] ?? '',
      userId: json['user'] is int ? json['user'] : 0,
      eventId: json['event'] ?? '',
      badgeNumber: json['badge_number'] ?? '',
      qrCodeData: json['qr_code_data'] ?? '',
      registrationDate: json['registration_date'] != null
          ? DateTime.parse(json['registration_date'])
          : DateTime.now(),
      planFile: json['plan_file'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'event': eventId,
      'badge_number': badgeNumber,
      'qr_code_data': qrCodeData,
      'registration_date': registrationDate.toIso8601String(),
      'plan_file': planFile,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    };
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? 'Participant';
  }
}
