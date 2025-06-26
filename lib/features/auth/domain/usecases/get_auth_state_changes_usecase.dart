import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetAuthStateChangesUseCase {
  const GetAuthStateChangesUseCase(this._repository);

  final AuthRepository _repository;

  Stream<UserEntity?> call() {
    return _repository.authStateChanges;
  }
}
