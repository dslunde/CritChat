import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fellowship_model.dart';

abstract class FellowshipFirestoreDataSource {
  Future<List<FellowshipModel>> getFellowships(List<String> fellowshipIds);
  Future<FellowshipModel> createFellowship(FellowshipModel fellowship);
  Future<FellowshipModel> updateFellowship(FellowshipModel fellowship);
  Future<void> deleteFellowship(String fellowshipId);
  Future<FellowshipModel?> getFellowshipById(String fellowshipId);
  Future<FellowshipModel> addMember(String fellowshipId, String userId);
  Future<FellowshipModel> removeMember(String fellowshipId, String userId);
  Future<List<FellowshipModel>> getAllFellowships();
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
}
