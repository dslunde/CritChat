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

class PollCreated extends PollState {
  final PollEntity poll;

  const PollCreated({required this.poll});

  @override
  List<Object> get props => [poll];
}

class PollVoteSuccess extends PollState {
  final String pollId;
  final List<String> optionIds;

  const PollVoteSuccess({required this.pollId, required this.optionIds});

  @override
  List<Object> get props => [pollId, optionIds];
}

class PollOptionAdded extends PollState {
  final String pollId;
  final PollOptionEntity option;

  const PollOptionAdded({required this.pollId, required this.option});

  @override
  List<Object> get props => [pollId, option];
}

class PollClosed extends PollState {
  final String pollId;

  const PollClosed({required this.pollId});

  @override
  List<Object> get props => [pollId];
}

class PollDeleted extends PollState {
  final String pollId;

  const PollDeleted({required this.pollId});

  @override
  List<Object> get props => [pollId];
}

class PollVoteRemoved extends PollState {
  final String pollId;
  final String? optionId;

  const PollVoteRemoved({required this.pollId, this.optionId});

  @override
  List<Object?> get props => [pollId, optionId];
}

class PollError extends PollState {
  final String message;
  final String? pollId;

  const PollError({required this.message, this.pollId});

  @override
  List<Object?> get props => [message, pollId];
}
