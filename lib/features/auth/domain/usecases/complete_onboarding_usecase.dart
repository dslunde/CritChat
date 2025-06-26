import 'package:critchat/features/auth/domain/entities/user_entity.dart';
import 'package:critchat/features/auth/domain/repositories/auth_repository.dart';

class CompleteOnboardingUseCase {
  const CompleteOnboardingUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call({
    required String userId,
    required String displayName,
    String? bio,
    required List<String> preferredSystems,
    required String experienceLevel,
  }) {
    return _repository.completeOnboarding(
      userId: userId,
      displayName: displayName,
      bio: bio,
      preferredSystems: preferredSystems,
      experienceLevel: experienceLevel,
    );
  }
}
