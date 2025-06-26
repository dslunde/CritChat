import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  ChatRealtimeDataSourceImpl({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _database = database ?? FirebaseDatabase.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

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
      final message = Message(
        id: messageRef.key!,
        senderId: currentUser.uid,
        senderName: await _getUserDisplayName(currentUser.uid),
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
