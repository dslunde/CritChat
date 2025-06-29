import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/chat/chat_realtime_datasource.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/core/gamification/gamification_service.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/polls/presentation/pages/fellowship_polls_page.dart';
import 'fellowship_info_page.dart';

class FellowshipChatPage extends StatefulWidget {
  final FellowshipEntity fellowship;

  const FellowshipChatPage({super.key, required this.fellowship});

  @override
  State<FellowshipChatPage> createState() => _FellowshipChatPageState();
}

class _FellowshipChatPageState extends State<FellowshipChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ChatRealtimeDataSource _chatDataSource = sl<ChatRealtimeDataSource>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  late String _chatId;
  Stream<List<Message>>? _messagesStream;
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamController<List<Message>>? _messagesController;
  List<Message> _lastMessages = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initializeChat();
  }

  void _initializeChat() {
    _chatId = ChatRealtimeDataSourceImpl.createFellowshipChatId(
      widget.fellowship.id,
    );

    // Create a broadcast StreamController that caches the last value
    _messagesController = StreamController<List<Message>>.broadcast(
      onListen: () {
        // When a new listener subscribes, immediately send the last known messages
        if (_lastMessages.isNotEmpty && !_messagesController!.isClosed) {
          _messagesController!.add(_lastMessages);
        }
      },
    );
    _messagesStream = _messagesController!.stream;

    // Listen to the Firebase stream and forward data to our controller
    _messagesSubscription = _chatDataSource
        .getMessages(_chatId)
        .listen(
          (messages) {
            _lastMessages = messages; // Cache the messages
            if (!_messagesController!.isClosed) {
              _messagesController!.add(messages);
            }
          },
          onError: (error) {
            if (!_messagesController!.isClosed) {
              _messagesController!.addError(error);
            }
          },
        );
  }

  void _onTabChanged() {
    // Tab changed - could be used for future functionality
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatDataSource.sendMessage(_chatId, content);

      // Award XP for sending a message
      try {
        final gamificationService = sl<GamificationService>();
        await gamificationService.awardXp(XpRewardType.sendMessage);
        debugPrint('✅ Awarded message send XP');
      } catch (e) {
        debugPrint('⚠️ Failed to award message send XP: $e');
      }

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
          // Tab Bar
          Container(
            color: AppColors.cardBackground,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.chat), text: 'Chat'),
                Tab(icon: Icon(Icons.poll), text: 'Polls'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Chat Tab
                _buildChatTab(),
                // Polls Tab
                FellowshipPollsPage(
                  fellowshipId: widget.fellowship.id,
                  fellowshipName: widget.fellowship.name,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // Messages List
        Expanded(
          child: _messagesStream == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<Message>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.errorColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading messages',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Start the conversation!',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    // Auto-scroll to bottom when new messages arrive
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _buildMessageBubble(message);
                      },
                    );
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
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
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
                  onSubmitted: (_) => _sendMessage(),
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
    );
  }

  Widget _buildMessageBubble(Message message) {
    final currentUserId = _auth.currentUser?.uid;
    final isMe = message.senderId == currentUserId;
    final isCharacterMessage = message.isCharacterMessage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show sender name and character indicator for all messages
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 40 : 40, 
              right: isMe ? 0 : 40,
              bottom: 4,
            ),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Text(
                    message.senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isCharacterMessage) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 10,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'as ${message.characterName}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else if (isCharacterMessage) ...[
                  // Show character indicator for sender's own messages
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'as ${message.characterName}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCharacterMessage 
                        ? const Color(0xFF7B1FA2) // Purple for character messages
                        : AppColors.primaryColor,
                    shape: BoxShape.circle,
                    border: isCharacterMessage
                        ? Border.all(color: const Color(0xFF9C27B0), width: 2)
                        : null,
                  ),
                  child: isCharacterMessage
                      ? const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 16,
                        )
                      : message.senderPhotoUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                message.senderPhotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                              ),
                            )
                          : Text(
                              message.senderName.isNotEmpty
                                  ? message.senderName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? (isCharacterMessage 
                            ? const Color(0xFF7B1FA2) // Purple for sender's character messages
                            : AppColors.primaryColor)
                        : isCharacterMessage
                            ? const Color(0xFFF3E5F5) // Light purple for character messages
                            : AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    border: isCharacterMessage
                        ? Border.all(
                            color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                            width: 2,
                          )
                        : (!isMe
                            ? Border.all(
                                color: AppColors.borderColor,
                                width: 1,
                              )
                            : null),
                    gradient: isCharacterMessage && !isMe
                        ? LinearGradient(
                            colors: [
                              const Color(0xFFF3E5F5),
                              const Color(0xFFF3E5F5).withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              message.content,
                              style: TextStyle(
                                color: isMe ? Colors.white : AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isCharacterMessage) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: isMe 
                                  ? 'Your character message'
                                  : 'AI-generated character response',
                              child: Icon(
                                isMe ? Icons.auto_awesome : Icons.psychology,
                                size: 16,
                                color: isMe 
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : const Color(0xFF9C27B0).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 14,
                              color: message.isRead
                                  ? Colors.lightBlueAccent
                                  : Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                // Show character avatar for sender's character messages
                if (isCharacterMessage)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B1FA2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF9C27B0), width: 2),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                else
                  const SizedBox(width: 32),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToFellowshipInfo(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => sl<FellowshipBloc>()),
            BlocProvider(create: (context) => sl<AuthBloc>()),
          ],
          child: FellowshipInfoPage(fellowship: widget.fellowship),
        ),
      ),
    );

    // If user left the fellowship, navigate back to fellowships page
    if (result == true && context.mounted) {
      Navigator.of(context).pop(true); // Pass success back to fellowships page
    }
  }

  Color _getGameSystemColor() {
    switch (widget.fellowship.gameSystem.toLowerCase()) {
      case 'd&d 5e':
        return const Color(0xFFD32F2F);
      case 'pathfinder':
        return const Color(0xFF8B4513);
      case 'call of cthulhu':
        return const Color(0xFF2E7D32);
      case 'shadowrun':
        return const Color(0xFF7B1FA2);
      case 'vampire: the masquerade':
        return const Color(0xFF8B0000);
      default:
        return AppColors.primaryColor;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _messagesSubscription?.cancel();
    _messagesController?.close();
    super.dispose();
  }
}
