import '../repositories/auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() async {
    await _authRepository.signOut();
  }
}
