import 'package:equatable/equatable.dart';

enum PollStatus { active, closed, expired }

class PollEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String creatorId;
  final String creatorName;
  final String fellowshipId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool allowCustomOptions;
  final bool allowMultipleChoice;
  final PollStatus status;
  final List<PollOptionEntity> options;
  final Map<String, List<String>> votes; // userId -> list of optionIds
  final Map<String, DateTime> voters; // userId -> timestamp when voted

  const PollEntity({
    required this.id,
    required this.title,
    this.description,
    required this.creatorId,
    required this.creatorName,
    required this.fellowshipId,
    required this.createdAt,
    required this.expiresAt,
    required this.allowCustomOptions,
    required this.allowMultipleChoice,
    required this.status,
    required this.options,
    required this.votes,
    required this.voters,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == PollStatus.active && !isExpired;
  bool get canVote => isActive;

  int get totalVotes =>
      votes.values.fold(0, (sum, userVotes) => sum + userVotes.length);

  bool hasUserVoted(String userId) => voters.containsKey(userId);

  List<String> getUserVotes(String userId) => votes[userId] ?? [];

  int getOptionVoteCount(String optionId) {
    return votes.values.fold(0, (count, userVotes) {
      return count + (userVotes.contains(optionId) ? 1 : 0);
    });
  }

  PollEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? creatorId,
    String? creatorName,
    String? fellowshipId,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? allowCustomOptions,
    bool? allowMultipleChoice,
    PollStatus? status,
    List<PollOptionEntity>? options,
    Map<String, List<String>>? votes,
    Map<String, DateTime>? voters,
  }) {
    return PollEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      fellowshipId: fellowshipId ?? this.fellowshipId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      allowCustomOptions: allowCustomOptions ?? this.allowCustomOptions,
      allowMultipleChoice: allowMultipleChoice ?? this.allowMultipleChoice,
      status: status ?? this.status,
      options: options ?? this.options,
      votes: votes ?? this.votes,
      voters: voters ?? this.voters,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    creatorId,
    creatorName,
    fellowshipId,
    createdAt,
    expiresAt,
    allowCustomOptions,
    allowMultipleChoice,
    status,
    options,
    votes,
    voters,
  ];
}

class PollOptionEntity extends Equatable {
  final String id;
  final String text;
  final String createdBy;
  final DateTime createdAt;

  const PollOptionEntity({
    required this.id,
    required this.text,
    required this.createdBy,
    required this.createdAt,
  });

  PollOptionEntity copyWith({
    String? id,
    String? text,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return PollOptionEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object> get props => [id, text, createdBy, createdAt];
}
