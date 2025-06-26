import 'package:equatable/equatable.dart';

abstract class FellowshipEvent extends Equatable {
  const FellowshipEvent();

  @override
  List<Object?> get props => [];
}

class GetFellowships extends FellowshipEvent {}

class CreateFellowship extends FellowshipEvent {
  final String name;
  final String description;
  final String gameSystem;
  final bool isPublic;

  const CreateFellowship({
    required this.name,
    required this.description,
    required this.gameSystem,
    required this.isPublic,
  });

  @override
  List<Object?> get props => [name, description, gameSystem, isPublic];
}

class InviteFriend extends FellowshipEvent {
  final String fellowshipId;
  final String friendId;

  const InviteFriend({required this.fellowshipId, required this.friendId});

  @override
  List<Object?> get props => [fellowshipId, friendId];
}

class RemoveMember extends FellowshipEvent {
  final String fellowshipId;
  final String memberId;

  const RemoveMember({required this.fellowshipId, required this.memberId});

  @override
  List<Object?> get props => [fellowshipId, memberId];
}

class DeleteFellowship extends FellowshipEvent {
  final String fellowshipId;

  const DeleteFellowship({required this.fellowshipId});

  @override
  List<Object?> get props => [fellowshipId];
}

class GetPublicFellowships extends FellowshipEvent {}

class GetUserFellowships extends FellowshipEvent {
  final String userId;

  const GetUserFellowships({required this.userId});

  @override
  List<Object?> get props => [userId];
}
