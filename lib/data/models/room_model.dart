// lib/data/models/room_model.dart

import 'package:equatable/equatable.dart';

class RoomModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int capacity;
  final String location;
  final List<SessionModel> sessions;
  final int currentParticipants;

  const RoomModel({
    required this.id,
    required this.name,
    this.description,
    required this.capacity,
    required this.location,
    this.sessions = const [],
    this.currentParticipants = 0,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'],
      capacity: json['capacity'] ?? 0,
      location: json['location'] ?? '',
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((s) => SessionModel.fromJson(s))
              .toList() ??
          [],
      currentParticipants: json['current_participants'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'capacity': capacity,
      'location': location,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'current_participants': currentParticipants,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        capacity,
        location,
        sessions,
        currentParticipants,
      ];
}

class SessionModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String roomId;
  final String? speakerName;
  final String? speakerTitle;
  final String? theme;
  final bool isLive;

  const SessionModel({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.roomId,
    this.speakerName,
    this.speakerTitle,
    this.theme,
    this.isLive = false,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      roomId: json['room_id'].toString(),
      speakerName: json['speaker_name'],
      speakerTitle: json['speaker_title'],
      theme: json['theme'],
      isLive: json['is_live'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'room_id': roomId,
      'speaker_name': speakerName,
      'speaker_title': speakerTitle,
      'theme': theme,
      'is_live': isLive,
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
        speakerName,
        speakerTitle,
        theme,
        isLive,
      ];
}