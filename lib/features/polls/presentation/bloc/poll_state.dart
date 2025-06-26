import 'package:equatable/equatable.dart';
import 'package:critchat/features/polls/domain/entities/poll_entity.dart';

abstract class PollState extends Equatable {
  const PollState();

  @override
  List<Object?> get props => [];
}

class PollInitial extends PollState {}

class PollLoading extends PollState {}

class PollsLoaded extends PollState {
  final List<PollEntity> polls;

  const PollsLoaded({required this.polls});

  @override
  List<Object> get props => [polls];
}

// Base class for states that include current polls
abstract class PollStateWithData extends PollState {
  final List<PollEntity> polls;

  const PollStateWithData({required this.polls});

  @override
  List<Object?> get props => [polls];
}

class PollCreated extends PollStateWithData {
  final PollEntity poll;

  const PollCreated({required this.poll, required super.polls});

  @override
  List<Object> get props => [poll, polls];
}

class PollVoteSuccess extends PollStateWithData {
  final String pollId;
  final List<String> optionIds;

  const PollVoteSuccess({
    required this.pollId,
    required this.optionIds,
    required super.polls,
  });

  @override
  List<Object> get props => [pollId, optionIds, polls];
}

class PollOptionAdded extends PollStateWithData {
  final String pollId;
  final PollOptionEntity option;

  const PollOptionAdded({
    required this.pollId,
    required this.option,
    required super.polls,
  });

  @override
  List<Object> get props => [pollId, option, polls];
}

class PollClosed extends PollStateWithData {
  final String pollId;

  const PollClosed({required this.pollId, required super.polls});

  @override
  List<Object> get props => [pollId, polls];
}

class PollDeleted extends PollStateWithData {
  final String pollId;

  const PollDeleted({required this.pollId, required super.polls});

  @override
  List<Object> get props => [pollId, polls];
}

class PollVoteRemoved extends PollStateWithData {
  final String pollId;
  final String? optionId;

  const PollVoteRemoved({
    required this.pollId,
    this.optionId,
    required super.polls,
  });

  @override
  List<Object?> get props => [pollId, optionId, polls];
}

class PollError extends PollState {
  final String message;
  final String? pollId;
  final List<PollEntity>? polls; // Optional polls to maintain UI

  const PollError({required this.message, this.pollId, this.polls});

  @override
  List<Object?> get props => [message, pollId, polls];
}
