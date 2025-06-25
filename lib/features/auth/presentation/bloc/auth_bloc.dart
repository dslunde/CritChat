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
        debugPrint(
          '🔍 Firebase Stream: User changed - ${user != null ? 'User exists' : 'No user'} (Current state: ${state.runtimeType})',
        );
        // Let the event handlers manage state emissions
        // This stream is just for listening to Firebase auth changes
        if (user != null) {
          debugPrint('🔍 Firebase Stream: Adding AuthStarted (user exists)');
          add(const AuthStarted());
        } else {
          debugPrint('🔍 Firebase Stream: Adding AuthStarted (no user)');
          add(const AuthStarted());
        }
      },
      onError: (error) {
        // Use debugPrint for development logging
        debugPrint('🚨 Firebase Stream: Error - $error');
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

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔍 SignIn: Starting sign-in process');
    emit(const AuthLoading());
    try {
      debugPrint('🔍 SignIn: Calling _signIn...');
      await _signIn(email: event.email, password: event.password);
      debugPrint('🔍 SignIn: _signIn completed, waiting 500ms...');
      // Wait for Firebase to settle
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('🔍 SignIn: Adding AuthStarted event');
      add(const AuthStarted());
    } catch (e) {
      debugPrint('🚨 SignIn: ERROR - ${e.toString()}');
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
      // Wait for Firebase to settle
      await Future.delayed(const Duration(milliseconds: 500));
      add(const AuthStarted());
    } catch (e) {
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
