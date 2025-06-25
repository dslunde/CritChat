import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<UserEntity> call({
    required String email,
    required String password,
  }) async {
    return await _authRepository.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
