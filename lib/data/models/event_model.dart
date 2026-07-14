import 'package:flutter/material.dart';

/// Event Model
class EventModel {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String? locationDetails;
  final String? logoUrl;
  final String? bannerUrl;
  final Color? primaryColor;
  final String? programmeFile; // PDF programme/schedule
  final String? guideFile; // PDF participant guide
  final String status;
  final int totalParticipants;
  final int totalExhibitors;
  final int totalRooms;
  final String? organizerContact;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? themes;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.locationDetails,
    this.logoUrl,
    this.bannerUrl,
    this.primaryColor,
    this.programmeFile,
    this.guideFile,
    required this.status,
    required this.totalParticipants,
    required this.totalExhibitors,
    required this.totalRooms,
    this.organizerContact,
    this.settings,
    this.themes,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  static Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      location: json['location'] as String,
      locationDetails: json['location_details'] as String?,
      logoUrl: json['logo'] as String?,
      bannerUrl: json['banner'] as String?,
      primaryColor: _parseHexColor(json['primary_color'] as String?),
      programmeFile: json['programme_file'] as String?,
      guideFile: json['guide_file'] as String?,
      status: json['status'] as String,
      totalParticipants: json['total_participants'] as int? ?? 0,
      totalExhibitors: json['total_exhibitors'] as int? ?? 0,
      totalRooms: json['total_rooms'] as int? ?? 0,
      organizerContact: json['organizer_contact'] as String?,
      settings: json['settings'] as Map<String, dynamic>?,
      themes: json['themes'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'location': location,
      'location_details': locationDetails,
      'logo': logoUrl,
      'banner': bannerUrl,
      'programme_file': programmeFile,
      'guide_file': guideFile,
      'status': status,
      'total_participants': totalParticipants,
      'total_exhibitors': totalExhibitors,
      'total_rooms': totalRooms,
      'organizer_contact': organizerContact,
      'settings': settings,
      'themes': themes,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool isActive() {
    final now = DateTime.now();
    return status == 'active' &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }

  bool isUpcoming() {
    final now = DateTime.now();
    return status == 'upcoming' && now.isBefore(startDate);
  }

  bool isCompleted() {
    final now = DateTime.now();
    return status == 'completed' || now.isAfter(endDate);
  }
}

/// Room Model
class Room {
  final String id;
  final String eventId;
  final String? eventName;
  final String name;
  final int? capacity;
  final String location;
  final int currentParticipants;
  final bool isActive;
  final int? sessionCount;
  final SessionInfo? nextSession;

  Room({
    required this.id,
    required this.eventId,
    this.eventName,
    required this.name,
    this.capacity,
    required this.location,
    required this.currentParticipants,
    required this.isActive,
    this.sessionCount,
    this.nextSession,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      eventId: json['event'] as String,
      eventName: json['event_name'] as String?,
      name: json['name'] as String,
      capacity: json['capacity'] as int?,
      location: json['location'] as String? ?? '',
      currentParticipants: json['current_participants'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      sessionCount: json['session_count'] as int?,
      nextSession: json['next_session'] != null
          ? SessionInfo.fromJson(json['next_session'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': eventId,
      'event_name': eventName,
      'name': name,
      'capacity': capacity,
      'location': location,
      'current_participants': currentParticipants,
      'is_active': isActive,
      'session_count': sessionCount,
      'next_session': nextSession?.toJson(),
    };
  }

  bool hasCapacity() {
    if (capacity == null) return true;
    return currentParticipants < capacity!;
  }

  double getOccupancyRate() {
    if (capacity == null || capacity == 0) return 0.0;
    return (currentParticipants / capacity!) * 100;
  }
}

/// Session Info (minimal for room's next session)
class SessionInfo {
  final String id;
  final String title;
  final DateTime startTime;
  final String? speakerName;

  SessionInfo({
    required this.id,
    required this.title,
    required this.startTime,
    this.speakerName,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      speakerName: json['speaker_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'speaker_name': speakerName,
    };
  }
}

/// Session Model (Full)
class Session {
  final String id;
  final String eventId;
  final String roomId;
  final String? roomName;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? speakerName;
  final String? speakerTitle;
  final String? speakerBio;
  final String? speakerPhotoUrl;
  final String? theme;
  final String status;
  final String? coverImageUrl;
  final Map<String, dynamic>? metadata;
  final bool isLive;
  final int durationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Session({
    required this.id,
    required this.eventId,
    required this.roomId,
    this.roomName,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.speakerName,
    this.speakerTitle,
    this.speakerBio,
    this.speakerPhotoUrl,
    this.theme,
    required this.status,
    this.coverImageUrl,
    this.metadata,
    required this.isLive,
    required this.durationMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      eventId: json['event'] as String,
      roomId: json['room'] as String,
      roomName: json['room_name'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      speakerName: json['speaker_name'] as String?,
      speakerTitle: json['speaker_title'] as String?,
      speakerBio: json['speaker_bio'] as String?,
      speakerPhotoUrl: json['speaker_photo_url'] as String?,
      theme: json['theme'] as String?,
      status: json['status'] as String,
      coverImageUrl: json['cover_image_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isLive: json['is_live'] as bool? ?? false,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': eventId,
      'room': roomId,
      'room_name': roomName,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'speaker_name': speakerName,
      'speaker_title': speakerTitle,
      'speaker_bio': speakerBio,
      'speaker_photo_url': speakerPhotoUrl,
      'theme': theme,
      'status': status,
      'cover_image_url': coverImageUrl,
      'metadata': metadata,
      'is_live': isLive,
      'duration_minutes': durationMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// User Event Assignment Model
class UserEventAssignment {
  final String id;
  final String userId;
  final String eventId;
  final String role;
  final String? permissions;
  final DateTime assignedAt;
  final bool isActive;

  UserEventAssignment({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.role,
    this.permissions,
    required this.assignedAt,
    this.isActive = true,
  });

  factory UserEventAssignment.fromJson(Map<String, dynamic> json) {
    return UserEventAssignment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      role: json['role'] as String,
      permissions: json['permissions'] as String?,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'role': role,
      'permissions': permissions,
      'assigned_at': assignedAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}
