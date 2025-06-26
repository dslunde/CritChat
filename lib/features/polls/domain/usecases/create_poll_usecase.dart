import 'package:critchat/features/polls/domain/entities/poll_entity.dart';
import 'package:critchat/features/polls/domain/repositories/poll_repository.dart';

class CreatePollUseCase {
  final PollRepository repository;

  CreatePollUseCase({required this.repository});

  Future<PollEntity> call({
    required String title,
    String? description,
    required String fellowshipId,
    required DateTime expiresAt,
    required bool allowCustomOptions,
    required bool allowMultipleChoice,
    required List<String> initialOptions,
  }) async {
    // Validation
    if (title.trim().isEmpty) {
      throw Exception('Poll title cannot be empty');
    }

    if (title.trim().length > 200) {
      throw Exception('Poll title cannot exceed 200 characters');
    }

    if (description != null && description.trim().length > 1000) {
      throw Exception('Poll description cannot exceed 1000 characters');
    }

    if (expiresAt.isBefore(DateTime.now())) {
      throw Exception('Poll expiration date must be in the future');
    }

    if (expiresAt.isAfter(DateTime.now().add(const Duration(days: 30)))) {
      throw Exception('Poll cannot be scheduled more than 30 days in advance');
    }

    if (initialOptions.isEmpty) {
      throw Exception('Poll must have at least one option');
    }

    if (initialOptions.length > 20) {
      throw Exception('Poll cannot have more than 20 initial options');
    }

    // Check for duplicate options
    final uniqueOptions = initialOptions
        .map((e) => e.trim().toLowerCase())
        .toSet();
    if (uniqueOptions.length != initialOptions.length) {
      throw Exception('Poll options must be unique');
    }

    // Check option length
    for (final option in initialOptions) {
      if (option.trim().isEmpty) {
        throw Exception('Poll options cannot be empty');
      }
      if (option.trim().length > 100) {
        throw Exception('Poll options cannot exceed 100 characters');
      }
    }

    return await repository.createPoll(
      title: title.trim(),
      description: description?.trim(),
      fellowshipId: fellowshipId,
      expiresAt: expiresAt,
      allowCustomOptions: allowCustomOptions,
      allowMultipleChoice: allowMultipleChoice,
      initialOptions: initialOptions.map((e) => e.trim()).toList(),
    );
  }
}
