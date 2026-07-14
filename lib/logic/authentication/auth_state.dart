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

  /// Note the explicit `clear*` flags: passing `errorMessage: null` cannot clear
  /// the field, because `null ?? this.errorMessage` keeps the old value. Without
  /// these, a stale login error would survive every subsequent emit.
  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? role,
    EventModel? event,
    List<EventModel>? availableEvents,
    String? errorMessage,
    bool clearAvailableEvents = false,
    bool clearError = false,
    bool clearEvent = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      role: role ?? this.role,
      event: clearEvent ? null : (event ?? this.event),
      availableEvents:
          clearAvailableEvents ? null : (availableEvents ?? this.availableEvents),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
