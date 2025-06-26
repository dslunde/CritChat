import 'package:critchat/features/polls/domain/entities/poll_entity.dart';

abstract class PollRepository {
  /// Get a stream of polls for a specific fellowship
  Stream<List<PollEntity>> getPollsForFellowship(String fellowshipId);

  /// Get a specific poll by ID
  Future<PollEntity?> getPollById(String pollId);

  /// Create a new poll in a fellowship
  Future<PollEntity> createPoll({
    required String title,
    String? description,
    required String fellowshipId,
    required DateTime expiresAt,
    required bool allowCustomOptions,
    required bool allowMultipleChoice,
    required List<String> initialOptions,
  });

  /// Vote on a poll option
  Future<void> voteOnPoll({
    required String pollId,
    required List<String> optionIds,
    String? fellowshipId,
  });

  /// Add a custom option to a poll (if allowed)
  Future<PollOptionEntity> addCustomOption({
    required String pollId,
    required String optionText,
  });

  /// Close a poll manually (only creator can do this)
  Future<void> closePoll(String pollId);

  /// Delete a poll (only creator can do this)
  Future<void> deletePoll(String pollId);

  /// Remove a vote from a poll
  Future<void> removeVote({
    required String pollId,
    String? optionId, // If null, removes all votes by the user
  });
}
