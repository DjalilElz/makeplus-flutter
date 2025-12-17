// lib/logic/authentication/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  requiresEventSelection, // New state for multi-event users
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? role;
  final EventModel? event;
  final List<EventModel>? availableEvents; // Available events for selection
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.role,
    this.event,
    this.availableEvents,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? role,
    EventModel? event,
    List<EventModel>? availableEvents,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      role: role ?? this.role,
      event: event ?? this.event,
      availableEvents: availableEvents ?? this.availableEvents,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, user, role, event, availableEvents, errorMessage];

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.email}, role: $role, event: ${event?.name}, availableEvents: ${availableEvents?.length}, error: $errorMessage)';
  }
}
