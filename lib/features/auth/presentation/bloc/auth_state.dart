import 'package:equatable/equatable.dart';
import 'package:critchat/features/auth/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, required this.needsOnboarding});

  final UserEntity user;
  final bool needsOnboarding;

  @override
  List<Object?> get props => [user, needsOnboarding];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthSigningOut extends AuthState {
  const AuthSigningOut();
}

class AuthOnboardingSuccess extends AuthState {
  const AuthOnboardingSuccess({required this.xpAmount, required this.message});

  final int xpAmount;
  final String message;

  @override
  List<Object?> get props => [xpAmount, message];
}

class AuthError extends AuthState {
  const AuthError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
