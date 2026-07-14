// lib/data/models/room_model.dart

import 'package:equatable/equatable.dart';

enum SessionStatus {
  notStarted, // Pas encore commencé
  inProgress, // En cours
  finished, // Terminé
}

class RoomModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int capacity;
  final String eventId;
  final List<SessionModel> sessions;
  final int currentParticipants;
  final bool isActive;

  const RoomModel({
    required this.id,
    required this.name,
    this.description,
    required this.capacity,
    required this.eventId,
    this.sessions = const [],
    this.currentParticipants = 0,
    this.isActive = true,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'],
      capacity: json['capacity'] ?? 0,
      eventId: json['event']?.toString() ?? '',
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((s) => SessionModel.fromJson(s))
              .toList() ??
          [],
      currentParticipants: json['current_participants'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'capacity': capacity,
      'event': eventId,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'current_participants': currentParticipants,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        capacity,
        eventId,
        sessions,
        currentParticipants,
        isActive,
      ];
}

class SessionModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String roomId;
  final String eventId;
  final String? speakerName;
  final String? speakerTitle;
  final String? theme;
  final bool isLive;
  final SessionStatus status;
  final String
      sessionType; // conference, atelier, communication, table_ronde, lunch_symposium, symposium, session_photo_communication
  final bool isPaid;
  final double? price;
  final int? maxParticipants; // Maximum participants for paid sessions
  final String? youtubeLiveUrl;

  const SessionModel({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.roomId,
    required this.eventId,
    this.speakerName,
    this.speakerTitle,
    this.theme,
    this.isLive = false,
    this.status = SessionStatus.notStarted,
    this.sessionType = 'conference',
    this.isPaid = false,
    this.price,
    this.maxParticipants,
    this.youtubeLiveUrl,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    SessionStatus status = SessionStatus.notStarted;
    if (json['status'] != null) {
      switch (json['status'].toString().toLowerCase()) {
        case 'live':
        case 'in_progress':
        case 'ongoing':
        case 'en_cours':
          status = SessionStatus.inProgress;
          break;
        case 'completed':
        case 'cancelled':
        case 'finished':
        case 'termine':
          status = SessionStatus.finished;
          break;
        case 'scheduled':
        case 'pas_encore':
        case 'not_started':
        default:
          status = SessionStatus.notStarted;
      }
    }

    return SessionModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      roomId: json['room']?.toString() ?? json['room_id']?.toString() ?? '',
      eventId: json['event']?.toString() ?? '',
      speakerName: json['speaker_name'],
      speakerTitle: json['speaker_title'],
      theme: json['theme'],
      isLive: json['is_live'] ?? status == SessionStatus.inProgress,
      status: status,
      sessionType: json['session_type'] ?? 'conference',
      isPaid: json['is_paid'] ?? false,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      maxParticipants: json['max_participants'] != null
          ? int.tryParse(json['max_participants'].toString())
          : null,
      youtubeLiveUrl: json['youtube_live_url'],
    );
  }

  Map<String, dynamic> toJson() {
    String statusString;
    switch (status) {
      case SessionStatus.inProgress:
        statusString = 'live';
        break;
      case SessionStatus.finished:
        statusString = 'completed';
        break;
      default:
        statusString = 'scheduled';
    }

    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'room': roomId,
      'event': eventId,
      'speaker_name': speakerName,
      'speaker_title': speakerTitle,
      'theme': theme,
      'is_live': isLive,
      'status': statusString,
      'session_type': sessionType,
      'is_paid': isPaid,
      'price': price?.toString(),
      'max_participants': maxParticipants,
      'youtube_live_url': youtubeLiveUrl,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startTime,
        endTime,
        roomId,
        eventId,
        speakerName,
        speakerTitle,
        theme,
        isLive,
        status,
        sessionType,
        isPaid,
        price,
        maxParticipants,
        youtubeLiveUrl,
      ];
}
