// lib/logic/authentication/auth_event.dart

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthSignupRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String role;

  const AuthSignupRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, fullName, role];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthEventSelectionRequested extends AuthEvent {
  final String eventId;

  const AuthEventSelectionRequested({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}
