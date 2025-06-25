import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Get current authenticated user
  Future<UserEntity?> getCurrentUser();

  /// Sign in with email and password
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign out current user
  Future<void> signOut();

  /// Update user profile
  Future<UserEntity> updateUserProfile(UserEntity user);

  /// Complete user onboarding with TTRPG preferences
  Future<UserEntity> completeOnboarding({
    required String userId,
    required String displayName,
    String? bio,
    required List<String> preferredSystems,
    required String experienceLevel,
  });

  /// Check if user is authenticated
  Stream<UserEntity?> get authStateChanges;
}
