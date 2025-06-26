import 'package:critchat/features/auth/domain/entities/user_entity.dart';
import 'package:critchat/features/auth/domain/repositories/auth_repository.dart';
import 'package:critchat/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:critchat/features/auth/data/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      return await _remoteDataSource.getCurrentUser();
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity> updateUserProfile(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      return await _remoteDataSource.updateUserProfile(userModel);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity> completeOnboarding({
    required String userId,
    required String displayName,
    String? bio,
    required List<String> preferredSystems,
    required String experienceLevel,
  }) async {
    try {
      return await _remoteDataSource.completeOnboarding(
        userId: userId,
        displayName: displayName,
        bio: bio,
        preferredSystems: preferredSystems,
        experienceLevel: experienceLevel,
      );
    } catch (e) {
      throw Exception('Failed to complete onboarding: ${e.toString()}');
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges;
  }
}
