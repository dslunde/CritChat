import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';
import 'package:critchat/features/fellowships/domain/repositories/fellowship_repository.dart';

class GetPublicFellowshipsUseCase {
  final FellowshipRepository repository;

  GetPublicFellowshipsUseCase({required this.repository});

  Future<List<FellowshipEntity>> call() {
    return repository.getPublicFellowships();
  }
}
