import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:critchat/features/polls/data/models/poll_model.dart';
import 'package:critchat/features/polls/domain/entities/poll_entity.dart';
import 'package:critchat/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:critchat/features/notifications/domain/entities/notification_entity.dart';

abstract class PollRealtimeDataSource {
  Stream<List<PollModel>> getPollsForFellowship(String fellowshipId);
  Future<PollModel?> getPollById(String pollId);
  Future<PollModel> createPoll({
    required String title,
    String? description,
    required String fellowshipId,
    required DateTime expiresAt,
    required bool allowCustomOptions,
    required bool allowMultipleChoice,
    required List<String> initialOptions,
  });
  Future<void> voteOnPoll({
    required String pollId,
    required List<String> optionIds,
    String? fellowshipId,
  });
  Future<PollOptionModel> addCustomOption({
    required String pollId,
    required String optionText,
  });
  Future<void> closePoll(String pollId);
  Future<void> deletePoll(String pollId);
  Future<void> removeVote({required String pollId, String? optionId});
}

class PollRealtimeDataSourceImpl implements PollRealtimeDataSource {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NotificationsRepository _notificationsRepository;

  PollRealtimeDataSourceImpl({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    required NotificationsRepository notificationsRepository,
  }) : _database = database ?? FirebaseDatabase.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationsRepository = notificationsRepository;

  /// Helper method to get user display name from Firestore
  Future<String> _getUserDisplayName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final displayName = userData?['displayName'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
      // Fallback to email prefix if no display name
      final currentUser = _auth.currentUser;
      if (currentUser?.email != null) {
        return currentUser!.email!.split('@')[0];
      }
      return 'User';
    } catch (e) {
      debugPrint('Failed to get user display name: $e');
      return 'User';
    }
  }

  /// Helper method to get fellowship members for poll notifications
  Future<List<String>> _getFellowshipMembers(
    String fellowshipId,
    String creatorId,
  ) async {
    try {
      final fellowshipDoc = await _firestore
          .collection('fellowships')
          .doc(fellowshipId)
          .get();

      if (fellowshipDoc.exists) {
        final data = fellowshipDoc.data();
        final members = List<String>.from(data?['memberIds'] ?? []);
        // Remove creator from recipients
        members.remove(creatorId);
        return members;
      }
    } catch (e) {
      debugPrint('Failed to get fellowship members: $e');
    }
    return [];
  }

  @override
  Stream<List<PollModel>> getPollsForFellowship(String fellowshipId) {
    return _database
        .ref('polls/fellowship_$fellowshipId')
        .orderByChild('createdAt')
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) return <PollModel>[];

          final List<PollModel> polls = [];
          data.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              polls.add(PollModel.fromJson(value, key));
            }
          });

          // Sort by creation date (newest first)
          polls.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return polls;
        });
  }

  @override
  Future<PollModel?> getPollById(String pollId) async {
    try {
      // Get all polls data (removed limitToFirst constraint)
      final snapshot = await _database.ref('polls').get();
      final data = snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return null;

      // Search through fellowship poll collections
      for (final fellowshipEntry in data.entries) {
        final fellowshipPolls = fellowshipEntry.value as Map<dynamic, dynamic>?;
        if (fellowshipPolls != null && fellowshipPolls.containsKey(pollId)) {
          final pollData = fellowshipPolls[pollId] as Map<dynamic, dynamic>;
          return PollModel.fromJson(pollData, pollId);
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get poll: $e');
    }
  }

  @override
  Future<PollModel> createPoll({
    required String title,
    String? description,
    required String fellowshipId,
    required DateTime expiresAt,
    required bool allowCustomOptions,
    required bool allowMultipleChoice,
    required List<String> initialOptions,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final pollRef = _database.ref('polls/fellowship_$fellowshipId').push();
      final pollId = pollRef.key!;
      final creatorName = await _getUserDisplayName(currentUser.uid);

      // Create initial options
      final optionsMap = <String, Map<String, dynamic>>{};
      for (int i = 0; i < initialOptions.length; i++) {
        final optionId = 'option_$i';
        optionsMap[optionId] = {
          'text': initialOptions[i],
          'createdBy': currentUser.uid,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        };
      }

      final pollData = {
        'title': title,
        'description': description,
        'creatorId': currentUser.uid,
        'creatorName': creatorName,
        'fellowshipId': fellowshipId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'allowCustomOptions': allowCustomOptions,
        'allowMultipleChoice': allowMultipleChoice,
        'status': PollStatus.active.name,
        'options': optionsMap,
        'votes': <String, dynamic>{},
        'voters': <String, dynamic>{},
      };

      await pollRef.set(pollData);

      // Create notifications for fellowship members about the new poll
      try {
        final members = await _getFellowshipMembers(
          fellowshipId,
          currentUser.uid,
        );

        // Get fellowship name
        final fellowshipDoc = await _firestore
            .collection('fellowships')
            .doc(fellowshipId)
            .get();

        final fellowshipName = fellowshipDoc.data()?['name'] ?? 'Fellowship';

        // Create notification for each member
        for (final memberId in members) {
          final notification = NotificationEntity(
            id: _database.ref('notifications').push().key!,
            userId: memberId,
            senderId: currentUser.uid,
            type: NotificationType
                .fellowshipMessage, // Using fellowshipMessage for polls
            title: 'New Poll Created',
            message:
                '$creatorName created a new poll in $fellowshipName: "$title"',
            data: {
              'pollId': pollId,
              'fellowshipId': fellowshipId,
              'fellowshipName': fellowshipName,
              'contentType': 'poll',
            },
            isRead: false,
            isActioned: false,
            createdAt: DateTime.now(),
          );

          await _notificationsRepository.createNotification(notification);
        }
        debugPrint(
          '✅ Created poll notifications for ${members.length} members',
        );
      } catch (e) {
        debugPrint('⚠️ Failed to create poll notifications: $e');
      }

      return PollModel.fromJson(pollData, pollId);
    } catch (e) {
      throw Exception('Failed to create poll: $e');
    }
  }

  @override
  Future<void> voteOnPoll({
    required String pollId,
    required List<String> optionIds,
    String? fellowshipId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      debugPrint('🗳️ Attempting to vote on poll: $pollId');
      debugPrint('🗳️ Fellowship ID: $fellowshipId');
      debugPrint('🗳️ Option IDs: $optionIds');
      debugPrint('🗳️ User ID: ${currentUser.uid}');

      // If fellowshipId is provided, use it directly
      if (fellowshipId != null) {
        final pollRef = _database.ref('polls/fellowship_$fellowshipId/$pollId');
        debugPrint(
          '🗳️ Using direct path: polls/fellowship_$fellowshipId/$pollId',
        );

        // Verify poll exists first
        final pollSnapshot = await pollRef.get();
        debugPrint('🗳️ Poll exists: ${pollSnapshot.exists}');
        if (!pollSnapshot.exists) {
          debugPrint('🚨 Poll not found at direct path');
          throw Exception('Poll not found');
        }

        debugPrint('🗳️ Poll data: ${pollSnapshot.value}');

        // Update votes and voters atomically
        final updates = <String, dynamic>{};
        updates['votes/${currentUser.uid}'] = optionIds;
        updates['voters/${currentUser.uid}'] =
            DateTime.now().millisecondsSinceEpoch;

        debugPrint('🗳️ Applying updates: $updates');
        await pollRef.update(updates);
        debugPrint('✅ Vote successfully recorded');
        return;
      }

      // Fallback: Find the poll in fellowship collections (less efficient)
      debugPrint('🗳️ Using fallback lookup method');
      final snapshot = await _database.ref('polls').get();
      final data = snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) {
        debugPrint('🚨 No polls data found in database');
        throw Exception('Poll not found');
      }

      debugPrint('🗳️ Available fellowship keys: ${data.keys.toList()}');

      String? foundFellowshipId;
      for (final fellowshipEntry in data.entries) {
        final fellowshipKey = fellowshipEntry.key as String;
        final fellowshipPolls = fellowshipEntry.value as Map<dynamic, dynamic>?;
        debugPrint('🗳️ Checking fellowship: $fellowshipKey');
        if (fellowshipPolls != null && fellowshipPolls.containsKey(pollId)) {
          foundFellowshipId = fellowshipKey;
          debugPrint('✅ Found poll in fellowship: $fellowshipKey');
          break;
        }
      }

      if (foundFellowshipId == null) {
        debugPrint('🚨 Poll not found in any fellowship');
        throw Exception('Poll not found');
      }

      final pollRef = _database.ref('polls/$foundFellowshipId/$pollId');

      // Update votes and voters atomically
      final updates = <String, dynamic>{};
      updates['votes/${currentUser.uid}'] = optionIds;
      updates['voters/${currentUser.uid}'] =
          DateTime.now().millisecondsSinceEpoch;

      await pollRef.update(updates);
      debugPrint('✅ Vote successfully recorded via fallback');
    } catch (e) {
      debugPrint('🚨 Vote failed: $e');
      throw Exception('Failed to vote on poll: $e');
    }
  }

  @override
  Future<PollOptionModel> addCustomOption({
    required String pollId,
    required String optionText,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Find the poll in fellowship collections
      final snapshot = await _database.ref('polls').get();
      final data = snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) throw Exception('Poll not found');

      String? fellowshipId;
      for (final fellowshipEntry in data.entries) {
        final fellowshipPolls = fellowshipEntry.value as Map<dynamic, dynamic>?;
        if (fellowshipPolls != null && fellowshipPolls.containsKey(pollId)) {
          fellowshipId = fellowshipEntry.key as String;
          break;
        }
      }

      if (fellowshipId == null) throw Exception('Poll not found');

      final optionRef = _database
          .ref('polls/$fellowshipId/$pollId/options')
          .push();
      final optionId = optionRef.key!;

      final optionData = {
        'text': optionText,
        'createdBy': currentUser.uid,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await optionRef.set(optionData);

      return PollOptionModel.fromJson(optionData, optionId);
    } catch (e) {
      throw Exception('Failed to add custom option: $e');
    }
  }

  @override
  Future<void> closePoll(String pollId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Find the poll in fellowship collections
      final snapshot = await _database.ref('polls').get();
      final data = snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) throw Exception('Poll not found');

      String? fellowshipId;
      Map<dynamic, dynamic>? pollData;
      for (final fellowshipEntry in data.entries) {
        final fellowshipPolls = fellowshipEntry.value as Map<dynamic, dynamic>?;
        if (fellowshipPolls != null && fellowshipPolls.containsKey(pollId)) {
          fellowshipId = fellowshipEntry.key as String;
          pollData = fellowshipPolls[pollId] as Map<dynamic, dynamic>;
          break;
        }
      }

      if (fellowshipId == null || pollData == null) {
        throw Exception('Poll not found');
      }

      // Check if user is the creator
      if (pollData['creatorId'] != currentUser.uid) {
        throw Exception('Only the poll creator can close the poll');
      }

      await _database
          .ref('polls/$fellowshipId/$pollId/status')
          .set(PollStatus.closed.name);

      // Create notifications for fellowship members about the poll closure
      try {
        final creatorName = await _getUserDisplayName(currentUser.uid);
        final members = await _getFellowshipMembers(
          fellowshipId.substring(11), // Remove "fellowship_" prefix
          currentUser.uid,
        );

        // Get fellowship name
        final fellowshipDoc = await _firestore
            .collection('fellowships')
            .doc(fellowshipId.substring(11))
            .get();

        final fellowshipName = fellowshipDoc.data()?['name'] ?? 'Fellowship';
        final pollTitle = pollData['title'] ?? 'Poll';

        // Create notification for each member
        for (final memberId in members) {
          final notification = NotificationEntity(
            id: _database.ref('notifications').push().key!,
            userId: memberId,
            senderId: currentUser.uid,
            type: NotificationType.fellowshipMessage,
            title: 'Poll Closed',
            message:
                '$creatorName closed the poll "$pollTitle" in $fellowshipName',
            data: {
              'pollId': pollId,
              'fellowshipId': fellowshipId.substring(11),
              'fellowshipName': fellowshipName,
              'contentType': 'pollClosed',
            },
            isRead: false,
            isActioned: false,
            createdAt: DateTime.now(),
          );

          await _notificationsRepository.createNotification(notification);
        }
        debugPrint(
          '✅ Created poll closure notifications for ${members.length} members',
        );
      } catch (e) {
        debugPrint('⚠️ Failed to create poll closure notifications: $e');
      }
    } catch (e) {
      throw Exception('Failed to close poll: $e');
    }
  }

  @override
  Future<void> deletePoll(String pollId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Find the poll in fellowship collections
      final snapshot = await _database.ref('polls').get();
      final data = snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) throw Exception('Poll not found');

      String? fellowshipId;
      Map<dynamic, dynamic>? pollData;
      for (final fellowshipEntry in data.entries) {
        final fellowshipPolls = fellowshipEntry.value as Map<dynamic, dynamic>?;
        if (fellowshipPolls != null && fellowshipPolls.containsKey(pollId)) {
          fellowshipId = fellowshipEntry.key as String;
          pollData = fellowshipPolls[pollId] as Map<dynamic, dynamic>;
          break;
        }
      }

      if (fellowshipId == null || pollData == null) {
        throw Exception('Poll not found');
      }

      // Check if user is the creator
      if (pollData['creatorId'] != currentUser.uid) {
        throw Exception('Only the poll creator can delete the poll');
      }

      await _database.ref('polls/$fellowshipId/$pollId').remove();
    } catch (e) {
      throw Exception('Failed to delete poll: $e');
    }
  }

  @override
  Future<void> removeVote({required String pollId, String? optionId}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Find the poll in fellowship collections
      final snapshot = await _database.ref('polls').get();
      final data = snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) throw Exception('Poll not found');

      String? fellowshipId;
      for (final fellowshipEntry in data.entries) {
        final fellowshipPolls = fellowshipEntry.value as Map<dynamic, dynamic>?;
        if (fellowshipPolls != null && fellowshipPolls.containsKey(pollId)) {
          fellowshipId = fellowshipEntry.key as String;
          break;
        }
      }

      if (fellowshipId == null) throw Exception('Poll not found');

      final pollRef = _database.ref('polls/$fellowshipId/$pollId');

      if (optionId == null) {
        // Remove all votes by the user
        final updates = <String, dynamic>{};
        updates['votes/${currentUser.uid}'] = null;
        updates['voters/${currentUser.uid}'] = null;
        await pollRef.update(updates);
      } else {
        // Remove specific option vote (for multiple choice polls)
        final votesSnapshot = await pollRef
            .child('votes/${currentUser.uid}')
            .get();
        final currentVotes = votesSnapshot.value;

        if (currentVotes is List) {
          final updatedVotes = List<String>.from(currentVotes)
            ..remove(optionId);
          if (updatedVotes.isEmpty) {
            // Remove user from voters if no votes left
            final updates = <String, dynamic>{};
            updates['votes/${currentUser.uid}'] = null;
            updates['voters/${currentUser.uid}'] = null;
            await pollRef.update(updates);
          } else {
            await pollRef.child('votes/${currentUser.uid}').set(updatedVotes);
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to remove vote: $e');
    }
  }
}
