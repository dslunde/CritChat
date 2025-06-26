import 'package:critchat/features/polls/domain/entities/poll_entity.dart';
import 'package:critchat/features/polls/domain/repositories/poll_repository.dart';

class GetFellowshipPollsUseCase {
  final PollRepository repository;

  GetFellowshipPollsUseCase({required this.repository});

  Stream<List<PollEntity>> call(String fellowshipId) {
    if (fellowshipId.isEmpty) {
      throw Exception('Fellowship ID cannot be empty');
    }

    return repository.getPollsForFellowship(fellowshipId);
  }
}
