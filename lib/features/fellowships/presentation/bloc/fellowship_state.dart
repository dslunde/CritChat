import 'package:equatable/equatable.dart';
import '../../domain/entities/fellowship_entity.dart';

abstract class FellowshipState extends Equatable {
  const FellowshipState();

  @override
  List<Object?> get props => [];
}

class FellowshipInitial extends FellowshipState {}

class FellowshipLoading extends FellowshipState {}

class FellowshipLoaded extends FellowshipState {
  final List<FellowshipEntity> fellowships;

  const FellowshipLoaded(this.fellowships);

  @override
  List<Object?> get props => [fellowships];
}

class FellowshipCreated extends FellowshipState {
  final FellowshipEntity fellowship;

  const FellowshipCreated(this.fellowship);

  @override
  List<Object?> get props => [fellowship];
}

class FriendInvited extends FellowshipState {}

class MemberRemoved extends FellowshipState {}

class FellowshipDeleted extends FellowshipState {}

class FellowshipError extends FellowshipState {
  final String message;

  const FellowshipError(this.message);

  @override
  List<Object?> get props => [message];
}
