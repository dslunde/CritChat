import '../entities/fellowship_entity.dart';
import '../repositories/fellowship_repository.dart';

class GetFellowshipsUseCase {
  final FellowshipRepository repository;

  GetFellowshipsUseCase({required this.repository});

  Future<List<FellowshipEntity>> call() {
    return repository.getFellowships();
  }
}
