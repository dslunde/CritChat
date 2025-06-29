import 'package:flutter/material.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/features/characters/domain/usecases/store_character_memory_usecase.dart';
import 'package:critchat/features/characters/domain/usecases/search_character_memories_usecase.dart';
import 'package:critchat/features/characters/domain/entities/character_entity.dart';
import 'package:critchat/features/characters/domain/entities/character_memory_entity.dart';

class CharacterMemoryWidget extends StatefulWidget {
  final CharacterEntity character;

  const CharacterMemoryWidget({
    super.key,
    required this.character,
  });

  @override
  State<CharacterMemoryWidget> createState() => _CharacterMemoryWidgetState();
}

class _CharacterMemoryWidgetState extends State<CharacterMemoryWidget> {
  final TextEditingController _memoryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isExpanded = false;
  List<CharacterMemoryEntity> _recentMemories = [];

  // Get use cases from dependency injection
  StoreCharacterMemoryUseCase? get _storeMemoryUseCase {
    try {
      return sl<StoreCharacterMemoryUseCase>();
    } catch (e) {
      return null;
    }
  }

  SearchCharacterMemoriesUseCase? get _searchMemoriesUseCase {
    try {
      return sl<SearchCharacterMemoriesUseCase>();
    } catch (e) {
      return null;
    }
  }

  bool get _isMemorySystemAvailable =>
      _storeMemoryUseCase != null && _searchMemoriesUseCase != null;

  @override
  void initState() {
    super.initState();
    _loadRecentMemories();
  }

  @override
  void dispose() {
    _memoryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentMemories() async {
    if (!_isMemorySystemAvailable) return;

    try {
      final memories = await _searchMemoriesUseCase!.getAllCharacterMemories(
        characterId: widget.character.id,
      );
      
      if (mounted) {
        setState(() {
          _recentMemories = memories.take(5).toList(); // Show last 5 memories
        });
      }
    } catch (e) {
      debugPrint('Failed to load recent memories: $e');
    }
  }

  Future<void> _addMemory() async {
    if (!_isMemorySystemAvailable) {
      _showNotAvailableDialog();
      return;
    }

    final content = _memoryController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _storeMemoryUseCase!.call(
        characterId: widget.character.id,
        userId: widget.character.userId,
        content: content,
        metadata: {
          'added_via': 'character_widget',
          'timestamp': DateTime.now().toIso8601String(),
        },
        source: 'user_input',
      );

      _memoryController.clear();
      _focusNode.unfocus();
      
      // Reload recent memories to show the new one
      await _loadRecentMemories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Memory added for ${widget.character.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to add memory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to add memory: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Character Memory System'),
        content: const Text(
          'The character memory system is not available. This requires vector database and AI services to be configured.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.character.name}\'s Memories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // Description
            Text(
              'Add memories, experiences, and notes about ${widget.character.name}. '
              'This information will help generate more authentic character responses.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            // Memory input
            TextField(
              controller: _memoryController,
              focusNode: _focusNode,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a memory, session note, NPC interaction, journal entry, or any character experience...',
                border: const OutlineInputBorder(),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addMemory,
                      ),
              ),
              enabled: !_isLoading,
              onSubmitted: (_) => _addMemory(),
            ),

            // Status indicator
            if (!_isMemorySystemAvailable) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Memory system not available (using basic mode)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],

            // Recent memories (expandable)
            if (_isExpanded && _recentMemories.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Recent Memories',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(_recentMemories.map((memory) => _buildMemoryItem(memory))),
            ],

            // Add memory hint
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Memory Tips',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Session notes: "In our last adventure, we met a mysterious shopkeeper"\n'
                      '• Character feelings: "I felt nervous about the dragon encounter"\n'
                      '• Relationships: "I trust Gandalf but am suspicious of the rogue"\n'
                      '• Background details: "I grew up in a small farming village"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryItem(CharacterMemoryEntity memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memory.summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(memory.contentType),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  memory.contentType,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(memory.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String contentType) {
    switch (contentType) {
      case 'session':
        return Colors.green;
      case 'npc_interaction':
        return Colors.blue;
      case 'journal':
        return Colors.purple;
      case 'backstory':
        return Colors.orange;
      case 'character_profile':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
} 