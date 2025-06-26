import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:critchat/features/fellowships/data/models/fellowship_model.dart';

abstract class FellowshipFirestoreDataSource {
  Future<List<FellowshipModel>> getFellowships(List<String> fellowshipIds);
  Future<FellowshipModel> createFellowship(FellowshipModel fellowship);
  Future<FellowshipModel> updateFellowship(FellowshipModel fellowship);
  Future<void> deleteFellowship(String fellowshipId);
  Future<FellowshipModel?> getFellowshipById(String fellowshipId);
  Future<FellowshipModel> addMember(String fellowshipId, String userId);
  Future<FellowshipModel> removeMember(String fellowshipId, String userId);
  Future<List<FellowshipModel>> getAllFellowships();
  Future<void> inviteFriendToFellowship(
    String fellowshipId,
    String friendId,
    String inviterName,
    String fellowshipName,
  );
  Future<void> acceptFellowshipInvite(String fellowshipId, String userId);
  Future<FellowshipModel?> getFellowshipByNameAndJoinCode(
    String name,
    String joinCode,
  );
}

class FellowshipFirestoreDataSourceImpl
    implements FellowshipFirestoreDataSource {
  final FirebaseFirestore _firestore;

  FellowshipFirestoreDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<FellowshipModel>> getFellowships(
    List<String> fellowshipIds,
  ) async {
    try {
      if (fellowshipIds.isEmpty) return [];

      final List<FellowshipModel> fellowships = [];

      // Firestore limits 'in' queries to 10 items, so we batch them
      for (int i = 0; i < fellowshipIds.length; i += 10) {
        final batch = fellowshipIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('fellowships')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in querySnapshot.docs) {
          fellowships.add(FellowshipModel.fromJson(doc.data(), doc.id));
        }
      }

      return fellowships;
    } catch (e) {
      throw Exception('Failed to get fellowships: $e');
    }
  }

  @override
  Future<FellowshipModel> createFellowship(FellowshipModel fellowship) async {
    try {
      final docRef = await _firestore
          .collection('fellowships')
          .add(fellowship.toJson());
      final newFellowship = fellowship.copyWith(id: docRef.id);

      // Update the document with the generated ID
      await docRef.update({'id': docRef.id});

      return newFellowship;
    } catch (e) {
      throw Exception('Failed to create fellowship: $e');
    }
  }

  @override
  Future<FellowshipModel> updateFellowship(FellowshipModel fellowship) async {
    try {
      await _firestore
          .collection('fellowships')
          .doc(fellowship.id)
          .update(fellowship.toJson());
      return fellowship;
    } catch (e) {
      throw Exception('Failed to update fellowship: $e');
    }
  }

  @override
  Future<void> deleteFellowship(String fellowshipId) async {
    try {
      await _firestore.collection('fellowships').doc(fellowshipId).delete();
    } catch (e) {
      throw Exception('Failed to delete fellowship: $e');
    }
  }

  @override
  Future<FellowshipModel?> getFellowshipById(String fellowshipId) async {
    try {
      final doc = await _firestore
          .collection('fellowships')
          .doc(fellowshipId)
          .get();
      if (!doc.exists) return null;

      return FellowshipModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get fellowship by ID: $e');
    }
  }

  @override
  Future<FellowshipModel> addMember(String fellowshipId, String userId) async {
    try {
      await _firestore.collection('fellowships').doc(fellowshipId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      final updatedFellowship = await getFellowshipById(fellowshipId);
      return updatedFellowship!;
    } catch (e) {
      throw Exception('Failed to add member to fellowship: $e');
    }
  }

  @override
  Future<FellowshipModel> removeMember(
    String fellowshipId,
    String userId,
  ) async {
    try {
      await _firestore.collection('fellowships').doc(fellowshipId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
      });

      final updatedFellowship = await getFellowshipById(fellowshipId);
      return updatedFellowship!;
    } catch (e) {
      throw Exception('Failed to remove member from fellowship: $e');
    }
  }

  @override
  Future<List<FellowshipModel>> getAllFellowships() async {
    try {
      final querySnapshot = await _firestore
          .collection('fellowships')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FellowshipModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all fellowships: $e');
    }
  }

  @override
  Future<void> inviteFriendToFellowship(
    String fellowshipId,
    String friendId,
    String inviterName,
    String fellowshipName,
  ) async {
    try {
      // Create fellowship invitation notification (NOT auto-adding)
      final notificationId = _firestore.collection('notifications').doc().id;

      // Only create the notification - do NOT add to fellowship yet
      await _firestore.collection('notifications').doc(notificationId).set({
        'userId': friendId,
        'senderId': fellowshipId, // Using fellowship ID as sender for invites
        'type': 'fellowshipInvite',
        'title': 'Fellowship Invitation',
        'message': '$inviterName invited you to join "$fellowshipName"',
        'data': {
          'fellowshipId': fellowshipId,
          'inviterName': inviterName,
          'fellowshipName': fellowshipName,
        },
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to invite friend to fellowship: $e');
    }
  }

  @override
  Future<void> acceptFellowshipInvite(
    String fellowshipId,
    String userId,
  ) async {
    try {
      // Add user to fellowship
      await _firestore.collection('fellowships').doc(fellowshipId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to accept fellowship invite: $e');
    }
  }

  @override
  Future<FellowshipModel?> getFellowshipByNameAndJoinCode(
    String name,
    String joinCode,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('fellowships')
          .where('name', isEqualTo: name)
          .where('joinCode', isEqualTo: joinCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return FellowshipModel.fromJson(doc.data(), doc.id);
    } catch (e) {
      throw Exception('Failed to get fellowship by name and join code: $e');
    }
  }
}
