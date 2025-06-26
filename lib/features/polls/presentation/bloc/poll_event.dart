import 'package:equatable/equatable.dart';

abstract class PollEvent extends Equatable {
  const PollEvent();

  @override
  List<Object?> get props => [];
}

class GetFellowshipPolls extends PollEvent {
  final String fellowshipId;

  const GetFellowshipPolls({required this.fellowshipId});

  @override
  List<Object> get props => [fellowshipId];
}

class CreatePoll extends PollEvent {
  final String title;
  final String? description;
  final String fellowshipId;
  final DateTime expiresAt;
  final bool allowCustomOptions;
  final bool allowMultipleChoice;
  final List<String> initialOptions;

  const CreatePoll({
    required this.title,
    this.description,
    required this.fellowshipId,
    required this.expiresAt,
    required this.allowCustomOptions,
    required this.allowMultipleChoice,
    required this.initialOptions,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    fellowshipId,
    expiresAt,
    allowCustomOptions,
    allowMultipleChoice,
    initialOptions,
  ];
}

class VoteOnPoll extends PollEvent {
  final String pollId;
  final List<String> optionIds;
  final String? fellowshipId;

  const VoteOnPoll({
    required this.pollId,
    required this.optionIds,
    this.fellowshipId,
  });

  @override
  List<Object?> get props => [pollId, optionIds, fellowshipId];
}

class AddCustomOption extends PollEvent {
  final String pollId;
  final String optionText;

  const AddCustomOption({required this.pollId, required this.optionText});

  @override
  List<Object> get props => [pollId, optionText];
}

class ClosePoll extends PollEvent {
  final String pollId;

  const ClosePoll({required this.pollId});

  @override
  List<Object> get props => [pollId];
}

class DeletePoll extends PollEvent {
  final String pollId;

  const DeletePoll({required this.pollId});

  @override
  List<Object> get props => [pollId];
}

class RemoveVote extends PollEvent {
  final String pollId;
  final String? optionId;

  const RemoveVote({required this.pollId, this.optionId});

  @override
  List<Object?> get props => [pollId, optionId];
}

class PollsUpdated extends PollEvent {
  final List<dynamic> polls; // Using dynamic to avoid import issues

  const PollsUpdated({required this.polls});

  @override
  List<Object> get props => [polls];
}
