import 'package:critchat/features/polls/domain/entities/poll_entity.dart';

class PollModel extends PollEntity {
  const PollModel({
    required super.id,
    required super.title,
    super.description,
    required super.creatorId,
    required super.creatorName,
    required super.fellowshipId,
    required super.createdAt,
    required super.expiresAt,
    required super.allowCustomOptions,
    required super.allowMultipleChoice,
    required super.status,
    required super.options,
    required super.votes,
    required super.voters,
  });

  factory PollModel.fromJson(Map<dynamic, dynamic> json, String pollId) {
    // Parse options
    final optionsData = json['options'] as Map<dynamic, dynamic>? ?? {};
    final options = optionsData.entries
        .map(
          (entry) => PollOptionModel.fromJson(
            entry.value as Map<dynamic, dynamic>,
            entry.key as String,
          ),
        )
        .toList();

    // Parse votes
    final votesData = json['votes'] as Map<dynamic, dynamic>? ?? {};
    final votes = <String, List<String>>{};
    for (final entry in votesData.entries) {
      final userId = entry.key as String;
      final userVotes = entry.value;
      if (userVotes is List) {
        votes[userId] = userVotes.map((e) => e.toString()).toList();
      } else if (userVotes is String) {
        // Support legacy single vote format
        votes[userId] = [userVotes];
      }
    }

    // Parse voters
    final votersData = json['voters'] as Map<dynamic, dynamic>? ?? {};
    final voters = <String, DateTime>{};
    for (final entry in votersData.entries) {
      final userId = entry.key as String;
      final timestamp = entry.value;
      if (timestamp is int) {
        voters[userId] = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }

    return PollModel(
      id: pollId,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      creatorId: json['creatorId'] as String? ?? '',
      creatorName: json['creatorName'] as String? ?? '',
      fellowshipId: json['fellowshipId'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] as int? ?? 0,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        json['expiresAt'] as int? ?? 0,
      ),
      allowCustomOptions: json['allowCustomOptions'] as bool? ?? false,
      allowMultipleChoice: json['allowMultipleChoice'] as bool? ?? false,
      status: _parseStatus(json['status'] as String?),
      options: options,
      votes: votes,
      voters: voters,
    );
  }

  Map<String, dynamic> toJson() {
    // Convert options to map
    final optionsMap = <String, Map<String, dynamic>>{};
    for (final option in options) {
      final optionModel = option is PollOptionModel
          ? option
          : PollOptionModel.fromEntity(option);
      optionsMap[option.id] = optionModel.toJson();
    }

    // Convert votes to map
    final votesMap = <String, dynamic>{};
    for (final entry in votes.entries) {
      votesMap[entry.key] = entry.value;
    }

    // Convert voters to map
    final votersMap = <String, int>{};
    for (final entry in voters.entries) {
      votersMap[entry.key] = entry.value.millisecondsSinceEpoch;
    }

    return {
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'fellowshipId': fellowshipId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'allowCustomOptions': allowCustomOptions,
      'allowMultipleChoice': allowMultipleChoice,
      'status': status.name,
      'options': optionsMap,
      'votes': votesMap,
      'voters': votersMap,
    };
  }

  static PollStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return PollStatus.active;
      case 'closed':
        return PollStatus.closed;
      case 'expired':
        return PollStatus.expired;
      default:
        return PollStatus.active;
    }
  }

  factory PollModel.fromEntity(PollEntity entity) {
    return PollModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      creatorId: entity.creatorId,
      creatorName: entity.creatorName,
      fellowshipId: entity.fellowshipId,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
      allowCustomOptions: entity.allowCustomOptions,
      allowMultipleChoice: entity.allowMultipleChoice,
      status: entity.status,
      options: entity.options,
      votes: entity.votes,
      voters: entity.voters,
    );
  }
}

class PollOptionModel extends PollOptionEntity {
  const PollOptionModel({
    required super.id,
    required super.text,
    required super.createdBy,
    required super.createdAt,
  });

  factory PollOptionModel.fromJson(
    Map<dynamic, dynamic> json,
    String optionId,
  ) {
    return PollOptionModel(
      id: optionId,
      text: json['text'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] as int? ?? 0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PollOptionModel.fromEntity(PollOptionEntity entity) {
    return PollOptionModel(
      id: entity.id,
      text: entity.text,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }
}
