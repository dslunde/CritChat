import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<UserModel> updateUserProfile(UserModel user);
  Future<UserModel> completeOnboarding({
    required String userId,
    required String displayName,
    String? bio,
    required List<String> preferredSystems,
    required String experienceLevel,
  });
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        final now = DateTime.now();
        final userData = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          bio: null,
          preferredSystems: const [],
          experienceLevel: null,
          totalXp: 0,
          joinedGroups: const [],
          createdAt: now,
          lastLogin: now,
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userData.toJson());

        return userData;
      }

      final data = userDoc.data();
      if (data == null) return null;

      return UserModel.fromJson(data, firebaseUser.uid);
    } catch (e) {
      print('Error in getCurrentUser: $e');
      return null;
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Sign in failed: User is null');
      }

      // Check if user document exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        final now = DateTime.now();
        final userData = UserModel(
          id: user.uid,
          email: email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          bio: null,
          preferredSystems: const [],
          experienceLevel: null,
          totalXp: 0,
          joinedGroups: const [],
          createdAt: now,
          lastLogin: now,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userData.toJson());

        return userData;
      } else {
        // Update last login for existing user
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        final updatedDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        return UserModel.fromJson(updatedDoc.data()!, user.uid);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Sign up failed: User is null');
      }

      // Create initial user document in Firestore
      final now = DateTime.now();
      final userData = UserModel(
        id: user.uid,
        email: email,
        displayName: null,
        photoUrl: null,
        bio: null,
        preferredSystems: const [],
        experienceLevel: null,
        totalXp: 0,
        joinedGroups: const [],
        createdAt: now,
        lastLogin: now,
      );

      await _firestore.collection('users').doc(user.uid).set(userData.toJson());

      return userData;
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign out failed: ${e.message}');
    }
  }

  @override
  Future<UserModel> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());

      final updatedDoc = await _firestore
          .collection('users')
          .doc(user.id)
          .get();

      return UserModel.fromJson(updatedDoc.data()!, user.id);
    } catch (e) {
      throw Exception('Update profile failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> completeOnboarding({
    required String userId,
    required String displayName,
    String? bio,
    required List<String> preferredSystems,
    required String experienceLevel,
  }) async {
    try {
      final updateData = {
        'displayName': displayName,
        'bio': bio,
        'preferredSystems': preferredSystems,
        'experienceLevel': experienceLevel,
      };

      await _firestore.collection('users').doc(userId).update(updateData);

      final updatedDoc = await _firestore.collection('users').doc(userId).get();

      return UserModel.fromJson(updatedDoc.data()!, userId);
    } catch (e) {
      throw Exception('Complete onboarding failed: ${e.toString()}');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (!userDoc.exists) {
          // Create user document if it doesn't exist
          final now = DateTime.now();
          final userData = UserModel(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
            bio: null,
            preferredSystems: const [],
            experienceLevel: null,
            totalXp: 0,
            joinedGroups: const [],
            createdAt: now,
            lastLogin: now,
          );

          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(userData.toJson());

          return userData;
        }

        final data = userDoc.data();
        if (data == null) return null;

        return UserModel.fromJson(data, firebaseUser.uid);
      } catch (e) {
        print('Error in authStateChanges: $e');
        return null;
      }
    });
  }
}
