import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<UserEntity> call({
    required String email,
    required String password,
  }) async {
    return await _authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
