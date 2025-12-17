// lib/data/models/user_model.dart

import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? username;
  final String role;
  final String? profilePhotoUrl;
  final bool? isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.username,
    required this.role,
    this.profilePhotoUrl,
    this.isActive,
  });

  String get fullName => '$firstName $lastName';

  String get displayName => fullName.trim().isEmpty ? email : fullName;

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
        isActive
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

  const AuthResponse({
    required this.user,
    required this.tokens,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: TokenPair.fromJson(json['tokens'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'tokens': tokens.toJson(),
    };
  }

  @override
  List<Object?> get props => [user, tokens];
}

class EventModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final String? role; // User's role in this event
  final String? status; // Event status: upcoming, ongoing, completed

  const EventModel({
    required this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.location,
    this.role,
    this.status,
  });

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
    };
  }

  @override
  List<Object?> get props =>
      [id, name, description, startDate, endDate, location, role, status];
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
