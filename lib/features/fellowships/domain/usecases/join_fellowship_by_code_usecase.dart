import 'package:critchat/features/fellowships/domain/repositories/fellowship_repository.dart';

class JoinFellowshipByCodeUseCase {
  final FellowshipRepository repository;

  JoinFellowshipByCodeUseCase({required this.repository});

  Future<bool> call({
    required String name,
    required String joinCode,
    required String userId,
  }) async {
    try {
      final result = await repository.joinFellowshipByCode(
        name,
        joinCode,
        userId,
      );
      if (!result) {
        throw Exception(
          'Could not join fellowship. Double check the name and join code match *exactly* what your GM gave you.',
        );
      }
      return result;
    } catch (e) {
      // Re-throw with a more specific error message if it's a general error
      if (e.toString().contains('Bad state: No element')) {
        throw Exception(
          'Could not join fellowship. Double check the name and join code match *exactly* what your GM gave you.',
        );
      }
      rethrow;
    }
  }
}
