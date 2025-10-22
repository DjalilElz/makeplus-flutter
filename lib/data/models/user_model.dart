/// User Model
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final bool isStaff;
  final String? role;
  final String? photoUrl;
  final List<UserAssignment>? assignments;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.isStaff = false,
    this.role,
    this.photoUrl,
    this.assignments,
  });

  // Getter for backward compatibility
  String get name => fullName;

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both int and String IDs (for Django and Supabase compatibility)
    final dynamic idValue = json['id'];
    final int id = idValue is int ? idValue : int.tryParse(idValue.toString()) ?? 0;

    return User(
      id: id,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      isStaff: json['is_staff'] as bool? ?? false,
      role: json['role'] as String?,
      photoUrl: json['photo_url'] as String?,
      assignments: json['assignments'] != null
          ? (json['assignments'] as List)
              .map((a) => UserAssignment.fromJson(a))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'is_staff': isStaff,
      'role': role,
      'photo_url': photoUrl,
    };
  }

  String getDisplayName() {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return username;
  }
}

/// User Assignment (Event Role)
class UserAssignment {
  final String eventId;
  final String eventName;
  final String role;
  final DateTime assignedAt;

  UserAssignment({
    required this.eventId,
    required this.eventName,
    required this.role,
    required this.assignedAt,
  });

  factory UserAssignment.fromJson(Map<String, dynamic> json) {
    return UserAssignment(
      eventId: json['event_id'] as String,
      eventName: json['event_name'] as String,
      role: json['role'] as String,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'event_name': eventName,
      'role': role,
      'assigned_at': assignedAt.toIso8601String(),
    };
  }
}

/// Auth Tokens Model
class AuthTokens {
  final String access;
  final String refresh;

  AuthTokens({
    required this.access,
    required this.refresh,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
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
}

/// Event Info (minimal)
class EventInfo {
  final String id;
  final String name;

  EventInfo({
    required this.id,
    required this.name,
  });

  factory EventInfo.fromJson(Map<String, dynamic> json) {
    return EventInfo(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

/// Auth Response Model (Login/Register response)
class AuthResponse {
  final User user;
  final AuthTokens tokens;
  final String role;
  final EventInfo? event;
  final String? message;

  AuthResponse({
    required this.user,
    required this.tokens,
    required this.role,
    this.event,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      role: json['role'] as String,
      event: json['event'] != null
          ? EventInfo.fromJson(json['event'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'tokens': tokens.toJson(),
      'role': role,
      'event': event?.toJson(),
      'message': message,
    };
  }
}

// Type alias for compatibility with existing code
typedef UserModel = User;
typedef TokenModel = AuthTokens;