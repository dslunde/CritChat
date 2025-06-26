import 'package:critchat/features/polls/domain/entities/poll_entity.dart';
import 'package:critchat/features/polls/domain/repositories/poll_repository.dart';
import 'package:critchat/features/polls/data/datasources/poll_realtime_datasource.dart';

class PollRepositoryImpl implements PollRepository {
  final PollRealtimeDataSource dataSource;

  PollRepositoryImpl({required this.dataSource});

  @override
  Stream<List<PollEntity>> getPollsForFellowship(String fellowshipId) {
    return dataSource
        .getPollsForFellowship(fellowshipId)
        .map((polls) => polls.cast<PollEntity>());
  }

  @override
  Future<PollEntity?> getPollById(String pollId) async {
    final pollModel = await dataSource.getPollById(pollId);
    return pollModel; // PollModel extends PollEntity, so this works
  }

  @override
  Future<PollEntity> createPoll({
    required String title,
    String? description,
    required String fellowshipId,
    required DateTime expiresAt,
    required bool allowCustomOptions,
    required bool allowMultipleChoice,
    required List<String> initialOptions,
  }) async {
    final pollModel = await dataSource.createPoll(
      title: title,
      description: description,
      fellowshipId: fellowshipId,
      expiresAt: expiresAt,
      allowCustomOptions: allowCustomOptions,
      allowMultipleChoice: allowMultipleChoice,
      initialOptions: initialOptions,
    );
    return pollModel; // PollModel extends PollEntity
  }

  @override
  Future<void> voteOnPoll({
    required String pollId,
    required List<String> optionIds,
  }) async {
    await dataSource.voteOnPoll(pollId: pollId, optionIds: optionIds);
  }

  @override
  Future<PollOptionEntity> addCustomOption({
    required String pollId,
    required String optionText,
  }) async {
    final optionModel = await dataSource.addCustomOption(
      pollId: pollId,
      optionText: optionText,
    );
    return optionModel; // PollOptionModel extends PollOptionEntity
  }

  @override
  Future<void> closePoll(String pollId) async {
    await dataSource.closePoll(pollId);
  }

  @override
  Future<void> deletePoll(String pollId) async {
    await dataSource.deletePoll(pollId);
  }

  @override
  Future<void> removeVote({required String pollId, String? optionId}) async {
    await dataSource.removeVote(pollId: pollId, optionId: optionId);
  }
}
