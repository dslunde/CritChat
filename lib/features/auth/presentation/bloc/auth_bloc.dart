import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/complete_onboarding_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetCurrentUserUseCase getCurrentUser,
    required SignInUseCase signIn,
    required SignUpUseCase signUp,
    required SignOutUseCase signOut,
    required GetAuthStateChangesUseCase getAuthStateChanges,
    required CompleteOnboardingUseCase completeOnboarding,
  }) : _getCurrentUser = getCurrentUser,
       _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _getAuthStateChanges = getAuthStateChanges,
       _completeOnboarding = completeOnboarding,
       super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthOnboardingCompleted>(_onOnboardingCompleted);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Listen to auth state changes - this is now the single source of truth
    _authStateSubscription = _getAuthStateChanges().listen(
      (user) {
        debugPrint(
          '🔍 Firebase Stream: User changed - ${user != null ? 'User exists' : 'No user'} (Current state: ${state.runtimeType})',
        );
        // Use the dedicated event for auth state changes
        add(AuthStateChanged(user));
      },
      onError: (error) {
        debugPrint('🚨 Firebase Stream: Error - $error');
        add(AuthStateChanged(null));
      },
    );
  }

  final GetCurrentUserUseCase _getCurrentUser;
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;
  final GetAuthStateChangesUseCase _getAuthStateChanges;
  final CompleteOnboardingUseCase _completeOnboarding;
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
    // Only emit loading if we're not already in a loading state
    if (state is! AuthLoading) {
      emit(const AuthLoading());
    }

    try {
      debugPrint('🔍 AuthStarted: Getting current user...');
      final user = await _getCurrentUser();
      debugPrint(
        '🔍 AuthStarted: User result: ${user != null ? 'Found user' : 'No user'}',
      );

      if (user != null) {
        final needsOnboarding =
            user.displayName == null ||
            user.experienceLevel == null ||
            user.preferredSystems.isEmpty;

        debugPrint('🔍 AuthStarted: Emitting AuthAuthenticated');
        emit(AuthAuthenticated(user: user, needsOnboarding: needsOnboarding));
      } else {
        debugPrint('🔍 AuthStarted: Emitting AuthUnauthenticated');
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('🚨 AuthStarted: ERROR - ${e.toString()}');
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    // This is now the single source of truth for auth state changes
    final user = event.user;

    if (user != null) {
      final needsOnboarding =
          user.displayName == null ||
          user.experienceLevel == null ||
          user.preferredSystems.isEmpty;

      debugPrint('🔍 AuthStateChanged: Emitting AuthAuthenticated');
      emit(AuthAuthenticated(user: user, needsOnboarding: needsOnboarding));
    } else {
      debugPrint('🔍 AuthStateChanged: Emitting AuthUnauthenticated');
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔍 SignIn: Starting sign-in process');
    emit(const AuthLoading());
    try {
      debugPrint('🔍 SignIn: Calling _signIn...');
      await _signIn(email: event.email, password: event.password);
      debugPrint('🔍 SignIn: _signIn completed successfully');
      // The auth state stream will handle the state change automatically
    } catch (e) {
      debugPrint('🚨 SignIn: ERROR - ${e.toString()}');
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔍 SignUp: Starting sign-up process');
    emit(const AuthLoading());
    try {
      debugPrint('🔍 SignUp: Calling _signUp...');
      await _signUp(email: event.email, password: event.password);
      debugPrint('🔍 SignUp: _signUp completed successfully');
      // The auth state stream will handle the state change automatically
    } catch (e) {
      debugPrint('🚨 SignUp: ERROR - ${e.toString()}');
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthSigningOut());
      await _signOut();
      // The goodbye page will handle the transition back to login
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
      final updatedUser = await _completeOnboarding(
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
