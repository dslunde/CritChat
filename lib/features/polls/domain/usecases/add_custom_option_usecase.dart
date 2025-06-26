import 'package:critchat/features/polls/domain/entities/poll_entity.dart';
import 'package:critchat/features/polls/domain/repositories/poll_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddCustomOptionUseCase {
  final PollRepository repository;
  final FirebaseAuth auth;

  AddCustomOptionUseCase({required this.repository, required this.auth});

  Future<PollOptionEntity> call({
    required String pollId,
    required String optionText,
  }) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to add options');
    }

    // Validation
    if (optionText.trim().isEmpty) {
      throw Exception('Option text cannot be empty');
    }

    if (optionText.trim().length > 100) {
      throw Exception('Option text cannot exceed 100 characters');
    }

    // Get the poll to validate
    final poll = await repository.getPollById(pollId);
    if (poll == null) {
      throw Exception('Poll not found');
    }

    // Check if poll allows custom options
    if (!poll.allowCustomOptions) {
      throw Exception('This poll does not allow custom options');
    }

    // Check if poll is still active
    if (!poll.canVote) {
      throw Exception('Cannot add options to an inactive poll');
    }

    // Check if option already exists (case-insensitive)
    final trimmedText = optionText.trim();
    final existingOptions = poll.options
        .map((option) => option.text.toLowerCase())
        .toSet();
    if (existingOptions.contains(trimmedText.toLowerCase())) {
      throw Exception('This option already exists');
    }

    // Check if poll has reached maximum options
    if (poll.options.length >= 50) {
      throw Exception('Poll cannot have more than 50 options');
    }

    return await repository.addCustomOption(
      pollId: pollId,
      optionText: trimmedText,
    );
  }
}
