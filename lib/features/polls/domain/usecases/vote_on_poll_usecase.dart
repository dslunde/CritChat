import 'package:flutter/foundation.dart';
import 'package:critchat/features/polls/domain/repositories/poll_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoteOnPollUseCase {
  final PollRepository repository;
  final FirebaseAuth auth;

  VoteOnPollUseCase({required this.repository, required this.auth});

  Future<void> call({
    required String pollId,
    required List<String> optionIds,
    String? fellowshipId,
  }) async {
    debugPrint('🎯 UseCase: Starting vote process');
    debugPrint('🎯 UseCase: Poll ID: $pollId');
    debugPrint('🎯 UseCase: Fellowship ID: $fellowshipId');
    debugPrint('🎯 UseCase: Option IDs: $optionIds');

    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to vote');
    }

    debugPrint('🎯 UseCase: User authenticated: ${currentUser.uid}');

    // Get the poll to validate
    final poll = await repository.getPollById(pollId);
    if (poll == null) {
      debugPrint('🚨 UseCase: Poll not found during validation');
      throw Exception('Poll not found');
    }

    debugPrint('🎯 UseCase: Poll found for validation: ${poll.title}');

    // Check if poll is still active
    if (!poll.canVote) {
      throw Exception('Poll is no longer active');
    }

    // Validate vote options
    if (optionIds.isEmpty) {
      throw Exception('Must select at least one option');
    }

    if (!poll.allowMultipleChoice && optionIds.length > 1) {
      throw Exception('This poll only allows one choice');
    }

    if (optionIds.length > 10) {
      throw Exception('Cannot vote for more than 10 options');
    }

    // Check if all option IDs exist in the poll
    final pollOptionIds = poll.options.map((option) => option.id).toSet();
    for (final optionId in optionIds) {
      if (!pollOptionIds.contains(optionId)) {
        throw Exception('Invalid option selected');
      }
    }

    // Check for duplicate option IDs
    if (optionIds.toSet().length != optionIds.length) {
      throw Exception('Cannot vote for the same option multiple times');
    }

    debugPrint('🎯 UseCase: All validations passed, calling repository');
    await repository.voteOnPoll(
      pollId: pollId,
      optionIds: optionIds,
      fellowshipId: fellowshipId,
    );
    debugPrint('✅ UseCase: Repository call completed');
  }
}
