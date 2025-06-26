import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthOnboardingCompleted extends AuthEvent {
  const AuthOnboardingCompleted({
    required this.displayName,
    this.bio,
    required this.preferredSystems,
    required this.experienceLevel,
  });

  final String displayName;
  final String? bio;
  final List<String> preferredSystems;
  final String experienceLevel;

  @override
  List<Object?> get props => [
    displayName,
    bio,
    preferredSystems,
    experienceLevel,
  ];
}

class AuthStateChanged extends AuthEvent {
  const AuthStateChanged(this.user);

  final UserEntity? user;

  @override
  List<Object?> get props => [user];
}
