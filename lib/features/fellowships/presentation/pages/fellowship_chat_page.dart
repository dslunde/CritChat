import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/fellowship_entity.dart';
import 'fellowship_info_page.dart';

class FellowshipChatPage extends StatefulWidget {
  final FellowshipEntity fellowship;

  const FellowshipChatPage({super.key, required this.fellowship});

  @override
  State<FellowshipChatPage> createState() => _FellowshipChatPageState();
}

class _FellowshipChatPageState extends State<FellowshipChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMockMessages();
  }

  void _loadMockMessages() {
    setState(() {
      _messages.addAll([
        ChatMessage(
          id: '1',
          senderId: 'user1',
          senderName: 'Alex Drake',
          content: 'Welcome to our fellowship! Ready for tonight\'s session?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isSystemMessage: false,
        ),
        ChatMessage(
          id: '2',
          senderId: 'system',
          senderName: 'System',
          content: 'Sarah Chen joined the fellowship',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          isSystemMessage: true,
        ),
        ChatMessage(
          id: '3',
          senderId: 'user2',
          senderName: 'Sarah Chen',
          content: 'Thanks for the invite! Looking forward to playing!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          isSystemMessage: false,
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getGameSystemColor(),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.fellowship.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.fellowship.memberCount} members',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _navigateToFellowshipInfo(context),
            tooltip: 'Fellowship Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(top: BorderSide(color: AppColors.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.primaryColor,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      fillColor: AppColors.backgroundColor,
                      filled: true,
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isSystemMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    final isCurrentUser =
        message.senderId == 'currentUser'; // Mock current user
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryColor,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppColors.primaryColor
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCurrentUser)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser
                            ? Colors.white70
                            : AppColors.primaryColor,
                      ),
                    ),
                  if (!isCurrentUser) const SizedBox(height: 2),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCurrentUser
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrentUser
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: message.isRead ? Colors.blue : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryColor,
              child: const Text(
                'Y',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getGameSystemColor() {
    switch (widget.fellowship.gameSystem.toLowerCase()) {
      case 'd&d 5e':
      case 'dungeons & dragons 5e':
        return Colors.red;
      case 'pathfinder 2e':
        return Colors.orange;
      case 'call of cthulhu 7e':
        return Colors.deepPurple;
      case 'shadowrun 6e':
        return Colors.cyan;
      case 'vampire: the masquerade 5e':
        return Colors.deepOrange;
      default:
        return AppColors.primaryColor;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'currentUser',
      senderName: 'You',
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
      isSystemMessage: false,
    );

    setState(() {
      _messages.add(newMessage);
    });

    _messageController.clear();
  }

  void _navigateToFellowshipInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FellowshipInfoPage(fellowship: widget.fellowship),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isSystemMessage;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isSystemMessage,
    this.isRead = false,
  });
}
