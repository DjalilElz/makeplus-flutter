import 'participant_model.dart';

/// QR Code Verification Result
/// Contains result of QR code verification including participant data
class QRVerificationResult {
  final bool valid;
  final ParticipantModel? participant;
  final bool accessGranted;
  final String? message;

  QRVerificationResult({
    required this.valid,
    this.participant,
    required this.accessGranted,
    this.message,
  });

  factory QRVerificationResult.fromJson(Map<String, dynamic> json) {
    return QRVerificationResult(
      valid: json['valid'] ?? false,
      participant: json['participant'] != null
          ? ParticipantModel.fromJson(json['participant'])
          : null,
      accessGranted: json['access_granted'] ?? false,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valid': valid,
      'participant': participant?.toJson(),
      'access_granted': accessGranted,
      'message': message,
    };
  }
}
