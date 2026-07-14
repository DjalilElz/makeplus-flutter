// lib/data/models/session_access_model.dart

import 'package:equatable/equatable.dart';

/// Payment Status for Session Access
enum PaymentStatus {
  pending, // Payment not yet completed
  paid, // Payment completed, access granted
  free, // Free session, no payment required
}

/// Session Access Model
/// Represents a participant's access to a session (especially paid sessions)
class SessionAccessModel extends Equatable {
  final String id;
  final String participantId;
  final String participantName;
  final String sessionId;
  final String sessionTitle;
  final String sessionType;
  final bool hasAccess;
  final PaymentStatus paymentStatus;
  final DateTime? paidAt;
  final double amountPaid;
  final DateTime createdAt;

  const SessionAccessModel({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.sessionId,
    required this.sessionTitle,
    required this.sessionType,
    required this.hasAccess,
    required this.paymentStatus,
    this.paidAt,
    this.amountPaid = 0.0,
    required this.createdAt,
  });

  factory SessionAccessModel.fromJson(Map<String, dynamic> json) {
    // Parse payment status
    PaymentStatus status = PaymentStatus.free;
    final statusStr = json['payment_status']?.toString().toLowerCase();
    if (statusStr != null) {
      switch (statusStr) {
        case 'pending':
          status = PaymentStatus.pending;
          break;
        case 'paid':
          status = PaymentStatus.paid;
          break;
        case 'free':
        default:
          status = PaymentStatus.free;
      }
    }

    return SessionAccessModel(
      id: json['id'].toString(),
      participantId: json['participant']?.toString() ?? '',
      participantName: json['participant_name'] ?? '',
      sessionId: json['session']?.toString() ?? '',
      sessionTitle: json['session_title'] ?? '',
      sessionType: json['session_type'] ?? 'conference',
      hasAccess: json['has_access'] ?? false,
      paymentStatus: status,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      amountPaid: json['amount_paid'] != null
          ? double.tryParse(json['amount_paid'].toString()) ?? 0.0
          : 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (paymentStatus) {
      case PaymentStatus.pending:
        statusStr = 'pending';
        break;
      case PaymentStatus.paid:
        statusStr = 'paid';
        break;
      case PaymentStatus.free:
        statusStr = 'free';
        break;
    }

    return {
      'id': id,
      'participant': participantId,
      'participant_name': participantName,
      'session': sessionId,
      'session_title': sessionTitle,
      'session_type': sessionType,
      'has_access': hasAccess,
      'payment_status': statusStr,
      'paid_at': paidAt?.toIso8601String(),
      'amount_paid': amountPaid,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if user can access the session
  bool canAccess() {
    return hasAccess &&
        (paymentStatus == PaymentStatus.paid ||
            paymentStatus == PaymentStatus.free);
  }

  /// Get status display text
  String getStatusText() {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Paiement en attente';
      case PaymentStatus.paid:
        return 'Payé';
      case PaymentStatus.free:
        return 'Gratuit';
    }
  }

  /// Get status color indicator
  String getStatusColor() {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'orange';
      case PaymentStatus.paid:
        return 'green';
      case PaymentStatus.free:
        return 'blue';
    }
  }

  @override
  List<Object?> get props => [
        id,
        participantId,
        participantName,
        sessionId,
        sessionTitle,
        sessionType,
        hasAccess,
        paymentStatus,
        paidAt,
        amountPaid,
        createdAt,
      ];
}
