import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetCurrentUserUseCase getCurrentUser,
    required SignInUseCase signIn,
    required SignUpUseCase signUp,
    required SignOutUseCase signOut,
    required AuthRepository authRepository,
  }) : _getCurrentUser = getCurrentUser,
       _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _authRepository = authRepository,
       super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);

    // Listen to auth state changes
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) {
        // Let the event handlers manage state emissions
        // This stream is just for listening to Firebase auth changes
        if (user != null) {
          add(const AuthStarted());
        } else {
          add(const AuthStarted());
        }
      },
      onError: (error) {
        // Use debugPrint for development logging
        debugPrint('Auth stream error: $error');
        add(const AuthStarted());
      },
    );
  }

  final GetCurrentUserUseCase _getCurrentUser;
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;
  final AuthRepository _authRepository;
  StreamSubscription? _authStateSubscription;

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _getCurrentUser();
      if (user != null) {
        final needsOnboarding =
            user.displayName == null ||
            user.experienceLevel == null ||
            user.preferredSystems.isEmpty;

        emit(AuthAuthenticated(user: user, needsOnboarding: needsOnboarding));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _signIn(email: event.email, password: event.password);
      // Longer delay to let Firebase Auth state settle and prevent flashing
      await Future.delayed(const Duration(milliseconds: 500));
      // Auth stream will handle the emission
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _signUp(email: event.email, password: event.password);
      // Longer delay to let Firebase Auth state settle and prevent flashing
      await Future.delayed(const Duration(milliseconds: 500));
      // Auth stream will handle the emission
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onOnboardingCompleted(
    AuthOnboardingCompleted event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;

    final currentState = state as AuthAuthenticated;
    emit(const AuthLoading());

    try {
      final updatedUser = await _authRepository.completeOnboarding(
        userId: currentState.user.id,
        displayName: event.displayName,
        bio: event.bio,
        preferredSystems: event.preferredSystems,
        experienceLevel: event.experienceLevel,
      );

      emit(AuthAuthenticated(user: updatedUser, needsOnboarding: false));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
