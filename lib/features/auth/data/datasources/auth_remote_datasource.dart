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

        try {
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(userData.toJson(), SetOptions(merge: true));

          return userData;
        } catch (e) {
          print('Failed to create user document in getCurrentUser: $e');
          return userData;
        }
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

      // Add a small delay to let Firebase Auth fully process
      await Future.delayed(const Duration(milliseconds: 200));

      final user = credential.user;
      if (user == null) {
        throw Exception('Sign in failed: User is null');
      }

      // Wait for user to be fully loaded
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser;

      if (refreshedUser == null) {
        throw Exception('Sign in failed: Unable to get user after sign in');
      }

      // Check if user document exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(refreshedUser.uid)
          .get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        final now = DateTime.now();
        final userData = UserModel(
          id: refreshedUser.uid,
          email: email,
          displayName: refreshedUser.displayName,
          photoUrl: refreshedUser.photoURL,
          bio: null,
          preferredSystems: const [],
          experienceLevel: null,
          totalXp: 0,
          joinedGroups: const [],
          createdAt: now,
          lastLogin: now,
        );

        try {
          await _firestore
              .collection('users')
              .doc(refreshedUser.uid)
              .set(userData.toJson(), SetOptions(merge: true));

          return userData;
        } catch (e) {
          // If document creation fails, try to get existing document
          print('Failed to create user document in signIn: $e');
          final retryDoc = await _firestore
              .collection('users')
              .doc(refreshedUser.uid)
              .get();

          if (retryDoc.exists && retryDoc.data() != null) {
            return UserModel.fromJson(retryDoc.data()!, refreshedUser.uid);
          }

          // If all else fails, return the userData we tried to create
          return userData;
        }
      } else {
        // Update last login for existing user
        await _firestore.collection('users').doc(refreshedUser.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        final updatedDoc = await _firestore
            .collection('users')
            .doc(refreshedUser.uid)
            .get();

        return UserModel.fromJson(updatedDoc.data()!, refreshedUser.uid);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      // Check for specific pigeon type casting errors
      if (e.toString().contains('PigeonUserDetails')) {
        throw Exception(
          'Sign in failed: Authentication timing error. Please try again.',
        );
      }
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

      // Add a small delay to let Firebase Auth fully process
      await Future.delayed(const Duration(milliseconds: 200));

      final user = credential.user;
      if (user == null) {
        throw Exception('Sign up failed: User is null');
      }

      // Wait for user to be fully loaded
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser;

      if (refreshedUser == null) {
        throw Exception('Sign up failed: Unable to get user after creation');
      }

      // Create initial user document in Firestore
      final now = DateTime.now();
      final userData = UserModel(
        id: refreshedUser.uid,
        email: email,
        displayName: refreshedUser.displayName,
        photoUrl: refreshedUser.photoURL,
        bio: null,
        preferredSystems: const [],
        experienceLevel: null,
        totalXp: 0,
        joinedGroups: const [],
        createdAt: now,
        lastLogin: now,
      );

      try {
        await _firestore
            .collection('users')
            .doc(refreshedUser.uid)
            .set(userData.toJson(), SetOptions(merge: true));

        return userData;
      } catch (firestoreError) {
        // If Firestore fails but Firebase Auth succeeded, still return user data
        print(
          'Firestore document creation failed during signup: $firestoreError',
        );
        return userData;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      // Check for specific pigeon type casting errors
      if (e.toString().contains('PigeonUserDetails')) {
        throw Exception(
          'Sign up failed: Authentication timing error. Please try again.',
        );
      }
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

          try {
            await _firestore
                .collection('users')
                .doc(firebaseUser.uid)
                .set(userData.toJson(), SetOptions(merge: true));

            return userData;
          } catch (e) {
            // If document creation fails, try to get existing document
            print('Failed to create user document: $e');
            final retryDoc = await _firestore
                .collection('users')
                .doc(firebaseUser.uid)
                .get();

            if (retryDoc.exists && retryDoc.data() != null) {
              return UserModel.fromJson(retryDoc.data()!, firebaseUser.uid);
            }

            // If all else fails, return the userData we tried to create
            return userData;
          }
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
