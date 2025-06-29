import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:critchat/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:critchat/features/notifications/domain/entities/notification_entity.dart';
import 'package:critchat/core/chat/chat_command_parser.dart';
import 'package:critchat/features/characters/domain/repositories/character_repository.dart';
import 'package:critchat/core/rag/rag_service.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderPhotoUrl;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String chatId;
  
  // Character message fields
  final bool isCharacterMessage;
  final String? characterId;
  final String? characterName;
  final String? originalPrompt; // The user's intended message

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.content,
    required this.timestamp,
    required this.isRead,
    required this.chatId,
    this.isCharacterMessage = false,
    this.characterId,
    this.characterName,
    this.originalPrompt,
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
      isCharacterMessage: json['isCharacterMessage'] as bool? ?? false,
      characterId: json['characterId'] as String?,
      characterName: json['characterName'] as String?,
      originalPrompt: json['originalPrompt'] as String?,
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
      'isCharacterMessage': isCharacterMessage,
      if (characterId != null) 'characterId': characterId,
      if (characterName != null) 'characterName': characterName,
      if (originalPrompt != null) 'originalPrompt': originalPrompt,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? chatId,
    bool? isCharacterMessage,
    String? characterId,
    String? characterName,
    String? originalPrompt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      chatId: chatId ?? this.chatId,
      isCharacterMessage: isCharacterMessage ?? this.isCharacterMessage,
      characterId: characterId ?? this.characterId,
      characterName: characterName ?? this.characterName,
      originalPrompt: originalPrompt ?? this.originalPrompt,
    );
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
  final CharacterRepository? _characterRepository;
  final RagService? _ragService;

  ChatRealtimeDataSourceImpl({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    required NotificationsRepository notificationsRepository,
    CharacterRepository? characterRepository,
    RagService? ragService,
  }) : _database = database ?? FirebaseDatabase.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationsRepository = notificationsRepository,
       _characterRepository = characterRepository,
       _ragService = ragService;

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

      // Check if this is an @as command
      if (ChatCommandParser.isAsCommand(content)) {
        await _processAsCommand(chatId, content);
      } else {
        await _sendRegularMessage(chatId, content);
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> _processAsCommand(String chatId, String content) async {
    final currentUser = _auth.currentUser!;
    
    // Validate command format
    final validation = ChatCommandValidator.validateAsCommand(content);
    if (!validation.isValid) {
      throw Exception(validation.error!);
    }
    
    // Parse the command
    final commandData = ChatCommandParser.parseAsCommand(content);
    if (commandData == null) {
      throw Exception('Invalid @as command format. Use: @as <character> <message>');
    }
    
    // Get user's character
    if (_characterRepository == null) {
      throw Exception('Character service not available. Please try again later.');
    }
    
    final userCharacter = await _characterRepository.getCharacterByNameAndUser(
      commandData.characterName,
      currentUser.uid,
    );
    
    if (userCharacter == null) {
      throw Exception('Character "${commandData.characterName}" not found. Create your character first!');
    }
    
    // Generate character response using RAG service
    String characterResponse;
    if (_ragService != null) {
      // Get recent chat context for better responses
      final recentMessages = await _getRecentMessages(chatId, 10);
      characterResponse = await _ragService.generateCharacterResponse(
        character: userCharacter,
        userPrompt: commandData.message,
        recentContext: recentMessages,
      );
    } else {
      // Fallback if RAG service is not available
      characterResponse = '${userCharacter.name} says: ${commandData.message}';
    }
    
    // Send the character message
    await _sendCharacterMessage(
      chatId,
      characterResponse,
      userCharacter.id,
      userCharacter.name,
      commandData.message,
    );
  }

  Future<void> _sendRegularMessage(String chatId, String content) async {
    final currentUser = _auth.currentUser!;
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
    await _updateChatMetadata(chatId, content, currentUser.uid);
    await _createMessageNotifications(chatId, message, senderName);
  }

  Future<void> _sendCharacterMessage(
    String chatId,
    String characterResponse,
    String characterId,
    String characterName,
    String originalPrompt,
  ) async {
    final currentUser = _auth.currentUser!;
    final messageRef = _database.ref('chats/$chatId/messages').push();
    final senderName = await _getUserDisplayName(currentUser.uid);

    final message = Message(
      id: messageRef.key!,
      senderId: currentUser.uid,
      senderName: senderName,
      senderPhotoUrl: currentUser.photoURL ?? '',
      content: characterResponse,
      timestamp: DateTime.now(),
      isRead: false,
      chatId: chatId,
      isCharacterMessage: true,
      characterId: characterId,
      characterName: characterName,
      originalPrompt: originalPrompt,
    );

    await messageRef.set(message.toJson());
    await _updateChatMetadata(chatId, '$characterName: $characterResponse', currentUser.uid);
    await _createCharacterMessageNotifications(chatId, message, characterName);
  }

  Future<List<Message>> _getRecentMessages(String chatId, int limit) async {
    try {
      final snapshot = await _database
          .ref('chats/$chatId/messages')
          .orderByChild('timestamp')
          .limitToLast(limit)
          .get();

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final List<Message> messages = [];
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          messages.add(Message.fromJson(value, key));
        }
      });

      // Sort by timestamp (oldest first)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      debugPrint('Failed to get recent messages: $e');
      return [];
    }
  }

  Future<void> _updateChatMetadata(String chatId, String content, String senderId) async {
    await _database.ref('chats/$chatId/metadata').update({
      'lastMessage': content,
      'lastMessageSender': senderId,
      'lastMessageTimestamp': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _createMessageNotifications(String chatId, Message message, String senderName) async {
    if (chatId.startsWith('direct_')) {
      // Direct message notification
      final recipientId = _getRecipientIdFromChatId(chatId, message.senderId);
      if (recipientId != null) {
        try {
          final notification = NotificationEntity(
            id: _database.ref('notifications').push().key!,
            userId: recipientId,
            senderId: message.senderId,
            type: NotificationType.directMessage,
            title: 'New Message',
            message:
                '$senderName: ${message.content.length > 50 ? '${message.content.substring(0, 50)}...' : message.content}',
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
      final fellowshipId = chatId.substring(11); // Remove "fellowship_" prefix
      try {
        final members = await _getFellowshipMembers(fellowshipId, message.senderId);
        final fellowshipDoc = await _firestore.collection('fellowships').doc(fellowshipId).get();
        final fellowshipName = fellowshipDoc.data()?['name'] ?? 'Fellowship';

        for (final memberId in members) {
          final notification = NotificationEntity(
            id: _database.ref('notifications').push().key!,
            userId: memberId,
            senderId: message.senderId,
            type: NotificationType.fellowshipMessage,
            title: 'Fellowship Message',
            message:
                '$senderName in $fellowshipName: ${message.content.length > 50 ? '${message.content.substring(0, 50)}...' : message.content}',
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
        debugPrint('✅ Created fellowship message notifications for ${members.length} members');
      } catch (e) {
        debugPrint('⚠️ Failed to create fellowship message notifications: $e');
      }
    }
  }

  Future<void> _createCharacterMessageNotifications(String chatId, Message message, String characterName) async {
    if (chatId.startsWith('fellowship_')) {
      final fellowshipId = chatId.substring(11);
      try {
        final members = await _getFellowshipMembers(fellowshipId, message.senderId);
        final fellowshipDoc = await _firestore.collection('fellowships').doc(fellowshipId).get();
        final fellowshipName = fellowshipDoc.data()?['name'] ?? 'Fellowship';

        for (final memberId in members) {
          final notification = NotificationEntity(
            id: _database.ref('notifications').push().key!,
            userId: memberId,
            senderId: message.senderId,
            type: NotificationType.fellowshipMessage,
            title: 'Character Message',
            message: '${message.senderName} as $characterName in $fellowshipName: ${message.content.length > 50 ? '${message.content.substring(0, 50)}...' : message.content}',
            data: {
              'chatId': chatId,
              'messageId': message.id,
              'fellowshipId': fellowshipId,
              'fellowshipName': fellowshipName,
              'isCharacterMessage': true,
              'characterName': characterName,
            },
            isRead: false,
            isActioned: false,
            createdAt: DateTime.now(),
          );

          await _notificationsRepository.createNotification(notification);
        }
        debugPrint('✅ Created character message notifications for ${members.length} members');
      } catch (e) {
        debugPrint('⚠️ Failed to create character message notifications: $e');
      }
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
