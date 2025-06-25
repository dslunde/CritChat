import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

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

class AuthError extends AuthState {
  const AuthError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
