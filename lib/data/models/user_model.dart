// lib/data/models/user_model.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class UserModel extends Equatable {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? username;
  final String role;
  final String? profilePhotoUrl;
  final bool? isActive;

  /// The badge payload minted by the backend (`UserProfile.get_or_create_qr_code`),
  /// returned as `qr_code` by both `/auth/token/` and `/auth/me/`.
  ///
  /// Contains `user_id`, `badge_id`, identity fields, and `paid_items` sourced from
  /// the caisse. Scanners `json.loads` this and look up `user_id`, so the badge must
  /// render **exactly this payload, JSON-encoded** — never a locally-built string.
  final Map<String, dynamic>? qrCode;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.username,
    required this.role,
    this.profilePhotoUrl,
    this.isActive,
    this.qrCode,
  });

  String get fullName => '$firstName $lastName';

  String get displayName => fullName.trim().isEmpty ? email : fullName;

  /// `badge_id` from the backend payload, e.g. `USER-42-A1B2C3D4`.
  String? get badgeId => qrCode?['badge_id'] as String?;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      username: json['username'] as String?,
      role: json['role'] as String? ?? 'participant',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      isActive: json['is_active'] as bool?,
      qrCode: json['qr_code'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'role': role,
      'profile_photo_url': profilePhotoUrl,
      'is_active': isActive,
      'qr_code': qrCode,
    };
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? role,
    String? profilePhotoUrl,
    bool? isActive,
    Map<String, dynamic>? qrCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      role: role ?? this.role,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      isActive: isActive ?? this.isActive,
      qrCode: qrCode ?? this.qrCode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        username,
        role,
        profilePhotoUrl,
        isActive,
        qrCode,
      ];
}

class TokenPair extends Equatable {
  final String access;
  final String refresh;

  const TokenPair({
    required this.access,
    required this.refresh,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': access,
      'refresh': refresh,
    };
  }

  @override
  List<Object?> get props => [access, refresh];
}

class AuthResponse extends Equatable {
  final UserModel user;
  final TokenPair tokens;
  final String? role;
  final EventModel? event;

  const AuthResponse({
    required this.user,
    required this.tokens,
    this.role,
    this.event,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Handle both old format (tokens nested) and new format (access/refresh at root)
    final TokenPair tokens;
    if (json.containsKey('tokens')) {
      tokens = TokenPair.fromJson(json['tokens'] as Map<String, dynamic>);
    } else {
      tokens = TokenPair(
        access: json['access'] as String,
        refresh: json['refresh'] as String,
      );
    }

    return AuthResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: tokens,
      role: json['role'] as String?,
      event: json['event'] != null
          ? EventModel.fromJson(json['event'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'tokens': tokens.toJson(),
      if (role != null) 'role': role,
      if (event != null) 'event': event!.toJson(),
    };
  }

  @override
  List<Object?> get props => [user, tokens, role, event];
}

class EventModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final String? role; // User's role in this event
  final String? status; // Event status: upcoming, active, completed, cancelled
  final String? programmeFile; // PDF programme/schedule URL
  final String? guideFile; // PDF participant guide URL
  final String? logoUrl;
  final String? bannerUrl;
  final Color? primaryColor;

  const EventModel({
    required this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.location,
    this.role,
    this.status,
    this.programmeFile,
    this.guideFile,
    this.logoUrl,
    this.bannerUrl,
    this.primaryColor,
  });

  static Color? parseHexColor(String? hex) {
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
      description: json['description'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      location: json['location'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String?,
      programmeFile: json['programme_file'] as String?,
      guideFile: json['guide_file'] as String?,
      logoUrl: json['logo'] as String?,
      bannerUrl: json['banner'] as String?,
      primaryColor: parseHexColor(json['primary_color'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'role': role,
      'status': status,
      'programme_file': programmeFile,
      'guide_file': guideFile,
      'logo': logoUrl,
      'banner': bannerUrl,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        startDate,
        endDate,
        location,
        role,
        status,
        programmeFile,
        guideFile,
        logoUrl,
        bannerUrl,
        primaryColor,
      ];
}

class LoginResponse extends Equatable {
  final UserModel user;
  final EventModel? event;
  final bool requiresEventSelection;
  final List<EventModel>? availableEvents;

  const LoginResponse({
    required this.user,
    this.event,
    this.requiresEventSelection = false,
    this.availableEvents,
  });

  @override
  List<Object?> get props =>
      [user, event, requiresEventSelection, availableEvents];
}
