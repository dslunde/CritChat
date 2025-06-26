import 'package:critchat/features/auth/domain/entities/user_entity.dart';
import 'package:critchat/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<UserEntity?> call() async {
    return await _authRepository.getCurrentUser();
  }
}
