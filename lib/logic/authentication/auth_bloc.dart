// lib/logic/authentication/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:makeplus/core/utils/app_logger.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthEventSelectionRequested>(_onAuthEventSelectionRequested);
    on<AuthSignupRequested>(_onAuthSignupRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthUserUpdated>(_onAuthUserUpdated);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final loginResponse = await authRepository.getCurrentUserWithEvent();

      if (loginResponse?.user != null) {
        final user = loginResponse!.user;
        AppLogger.d('🔐 AUTH CHECK - User session restored');
        AppLogger.d('👤 User: ${user.email}');
        AppLogger.d('🎭 Role: ${user.role}');
        AppLogger.d('🎪 Event: ${loginResponse.event?.name ?? "NO EVENT"}');

        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          role: user.role,
          event: loginResponse.event,
          clearEvent: loginResponse.event == null,
        ));
      } else {
        AppLogger.d('🔐 AUTH CHECK - No saved session, showing login');
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      AppLogger.d('❌ AUTH CHECK ERROR: $e');
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final loginResponse = await authRepository.login(
        email: event.email,
        password: event.password,
      );

      // Check if user needs to select an event
      if (loginResponse.requiresEventSelection) {
        AppLogger.d('🔄 MULTI-EVENT USER - Showing event selection');
        emit(state.copyWith(
          status: AuthStatus.requiresEventSelection,
          user: loginResponse.user,
          availableEvents: loginResponse.availableEvents,
        ));
        return;
      }

      AppLogger.d('🔐 AUTH BLOC - Login successful');
      AppLogger.d('👤 User: ${loginResponse.user.email}');
      AppLogger.d('🎭 Role: ${loginResponse.user.role}');
      AppLogger.d('🎪 Event: ${loginResponse.event?.name ?? "NO EVENT"}');

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: loginResponse.user,
        role: loginResponse.user.role,
        event: loginResponse.event,
        clearEvent: loginResponse.event == null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthEventSelectionRequested(
    AuthEventSelectionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final loginResponse = await authRepository.selectEvent(event.eventId);

      AppLogger.d('🔐 AUTH BLOC - Event selected successfully');
      AppLogger.d('👤 User: ${loginResponse.user.email}');
      AppLogger.d('🎭 Role: ${loginResponse.user.role}');
      AppLogger.d('🎪 Event: ${loginResponse.event?.name ?? "NO EVENT"}');

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: loginResponse.user,
        role: loginResponse.user.role,
        event: loginResponse.event,
        clearEvent: loginResponse.event == null,
        clearAvailableEvents: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthSignupRequested(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final signupResponse = await authRepository.signup(
        email: event.email,
        password: event.password,
        name: event.fullName,
        role: event.role,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: signupResponse.user,
        role: signupResponse.user.role,
        event: signupResponse.event,
        clearEvent: signupResponse.event == null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      await authRepository.logout();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      await authRepository.resetPassword(event.email);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Password reset email sent!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onAuthUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(user: event.user));
  }
}
