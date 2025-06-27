import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:critchat/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:critchat/features/notifications/domain/entities/notification_entity.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String chatId;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.content,
    required this.timestamp,
    required this.isRead,
    required this.chatId,
  });

  factory Message.fromJson(Map<dynamic, dynamic> json, String messageId) {
    return Message(
      id: messageId,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderPhotoUrl: json['senderPhotoUrl'] as String? ?? '',
      content: json['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isRead: json['isRead'] as bool? ?? false,
      chatId: json['chatId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'chatId': chatId,
    };
  }
}

abstract class ChatRealtimeDataSource {
  Stream<List<Message>> getMessages(String chatId);
  Future<void> sendMessage(String chatId, String content);
  Future<void> markMessageAsRead(String chatId, String messageId);
  Future<void> markAllMessagesAsRead(String chatId);
}

class ChatRealtimeDataSourceImpl implements ChatRealtimeDataSource {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NotificationsRepository _notificationsRepository;

  ChatRealtimeDataSourceImpl({
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

  /// Helper method to extract recipient ID from chat ID
  String? _getRecipientIdFromChatId(String chatId, String senderId) {
    if (chatId.startsWith('direct_')) {
      // Direct chat format: "direct_userId1_userId2"
      final parts = chatId.substring(7).split('_'); // Remove "direct_" prefix
      if (parts.length == 2) {
        return parts[0] == senderId ? parts[1] : parts[0];
      }
    }
    return null;
  }

  /// Helper method to get fellowship members for group notifications
  Future<List<String>> _getFellowshipMembers(
    String fellowshipId,
    String senderId,
  ) async {
    try {
      final fellowshipDoc = await _firestore
          .collection('fellowships')
          .doc(fellowshipId)
          .get();

      if (fellowshipDoc.exists) {
        final data = fellowshipDoc.data();
        final members = List<String>.from(data?['memberIds'] ?? []);
        // Remove sender from recipients
        members.remove(senderId);
        return members;
      }
    } catch (e) {
      debugPrint('Failed to get fellowship members: $e');
    }
    return [];
  }

  @override
  Stream<List<Message>> getMessages(String chatId) {
    return _database
        .ref('chats/$chatId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null) return <Message>[];

          final List<Message> messages = [];
          data.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              messages.add(Message.fromJson(value, key));
            }
          });

          // Sort by timestamp (oldest first)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  @override
  Future<void> sendMessage(String chatId, String content) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final messageRef = _database.ref('chats/$chatId/messages').push();
      final senderName = await _getUserDisplayName(currentUser.uid);

      final message = Message(
        id: messageRef.key!,
        senderId: currentUser.uid,
        senderName: senderName,
        senderPhotoUrl: currentUser.photoURL ?? '',
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        chatId: chatId,
      );

      await messageRef.set(message.toJson());

      // Update chat metadata (last message, timestamp)
      await _database.ref('chats/$chatId/metadata').update({
        'lastMessage': content,
        'lastMessageSender': currentUser.uid,
        'lastMessageTimestamp': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Create notifications based on chat type
      if (chatId.startsWith('direct_')) {
        // Direct message notification
        final recipientId = _getRecipientIdFromChatId(chatId, currentUser.uid);
        if (recipientId != null) {
          try {
            final notification = NotificationEntity(
              id: _database.ref('notifications').push().key!,
              userId: recipientId,
              senderId: currentUser.uid,
              type: NotificationType.directMessage,
              title: 'New Message',
              message:
                  '$senderName: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}',
              data: {'chatId': chatId, 'messageId': message.id},
              isRead: false,
              isActioned: false,
              createdAt: DateTime.now(),
            );

            await _notificationsRepository.createNotification(notification);
            debugPrint('✅ Created direct message notification');
          } catch (e) {
            debugPrint('⚠️ Failed to create direct message notification: $e');
          }
        }
      } else if (chatId.startsWith('fellowship_')) {
        // Fellowship message notification
        final fellowshipId = chatId.substring(
          11,
        ); // Remove "fellowship_" prefix
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
              type: NotificationType.fellowshipMessage,
              title: 'Fellowship Message',
              message:
                  '$senderName in $fellowshipName: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}',
              data: {
                'chatId': chatId,
                'messageId': message.id,
                'fellowshipId': fellowshipId,
                'fellowshipName': fellowshipName,
              },
              isRead: false,
              isActioned: false,
              createdAt: DateTime.now(),
            );

            await _notificationsRepository.createNotification(notification);
          }
          debugPrint(
            '✅ Created fellowship message notifications for ${members.length} members',
          );
        } catch (e) {
          debugPrint(
            '⚠️ Failed to create fellowship message notifications: $e',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _database.ref('chats/$chatId/messages/$messageId').update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  @override
  Future<void> markAllMessagesAsRead(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final messagesSnapshot = await _database
          .ref('chats/$chatId/messages')
          .get();
      final data = messagesSnapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return;

      final Map<String, dynamic> updates = {};
      data.forEach((messageId, messageData) {
        if (messageData is Map<dynamic, dynamic>) {
          final senderId = messageData['senderId'] as String;
          // Only mark messages from other users as read
          if (senderId != currentUser.uid) {
            updates['chats/$chatId/messages/$messageId/isRead'] = true;
          }
        }
      });

      if (updates.isNotEmpty) {
        await _database.ref().update(updates);
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Create a chat ID for direct messages between two users
  static String createDirectChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'direct_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Create a chat ID for fellowship group chats
  static String createFellowshipChatId(String fellowshipId) {
    return 'fellowship_$fellowshipId';
  }
}
