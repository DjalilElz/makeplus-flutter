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
  List<Object?> get props => [id, email, firstName, lastName, username, role, profilePhotoUrl, isActive];
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