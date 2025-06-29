import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/widgets/app_top_bar.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/core/gamification/gamification_service.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';
import 'package:critchat/features/characters/presentation/bloc/character_bloc.dart';
import 'package:critchat/features/characters/presentation/bloc/character_event.dart';
import 'package:critchat/features/characters/presentation/bloc/character_state.dart';
import 'package:critchat/features/characters/presentation/widgets/character_memory_widget.dart';
import 'package:critchat/features/characters/domain/entities/character_entity.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/gamification/presentation/widgets/xp_progress_widget.dart';

class ForMePage extends StatefulWidget {
  const ForMePage({super.key});

  @override
  State<ForMePage> createState() => _ForMePageState();
}

class _ForMePageState extends State<ForMePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _personalityController = TextEditingController();
  final _backstoryController = TextEditingController();
  final _speechPatternsController = TextEditingController();
  final _quotesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _personalityController.dispose();
    _backstoryController.dispose();
    _speechPatternsController.dispose();
    _quotesController.dispose();
    super.dispose();
  }

  void _populateForm(CharacterEntity character) {
    _nameController.text = character.name;
    _descriptionController.text = character.description;
    _personalityController.text = character.personality;
    _backstoryController.text = character.backstory;
    _speechPatternsController.text = character.speechPatterns;
    _quotesController.text = character.quotes.join(', ');
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _personalityController.clear();
    _backstoryController.clear();
    _speechPatternsController.clear();
    _quotesController.clear();
  }

  List<String> _parseCommaSeparated(String text) {
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CharacterBloc>(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              const AppTopBar(backgroundColor: AppColors.primaryColor),

              // Content Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppColors.backgroundColor,
                  child: BlocBuilder<CharacterBloc, CharacterState>(
                    builder: (context, characterState) {
                      return BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, authState) {
                          if (authState is! AuthAuthenticated) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          // Trigger character loading if we haven't started yet
                          if (characterState is CharacterInitial) {
                            context.read<CharacterBloc>().add(GetUserCharacter(userId: authState.user.id));
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with XP
                                _buildHeader(authState),
                                const SizedBox(height: 24),

                                // Character Management Section
                                _buildCharacterSection(context, characterState),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthAuthenticated authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${authState.user.displayName ?? 'Adventurer'}!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // XP Progress
        StreamBuilder<XpEntity>(
          stream: sl<GamificationService>().getCurrentUserXpStream(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return XpProgressWidget(
                xpEntity: snapshot.data!,
                showLabel: true,
                compact: false,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildCharacterSection(BuildContext context, CharacterState characterState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Icon(Icons.person_4, color: AppColors.primaryColor, size: 28),
            const SizedBox(width: 12),
            const Text(
              'My Character',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Create and manage your TTRPG character for AI-powered @as commands',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Character State Handling
        if (characterState is CharacterLoading)
          const Center(child: CircularProgressIndicator())
        else if (characterState is CharacterError)
          _buildErrorWidget(context, characterState.message)
        else if (characterState is CharacterLoaded)
          _buildExistingCharacter(context, characterState.character)
        else
          _buildCreateCharacter(context),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorColor, size: 32),
          const SizedBox(height: 8),
          Text(
            'Error: $message',
            style: const TextStyle(color: AppColors.errorColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final authState = context.read<AuthBloc>().state as AuthAuthenticated;
              context.read<CharacterBloc>().add(GetUserCharacter(userId: authState.user.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingCharacter(BuildContext context, CharacterEntity character) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Character Info Card (Tappable)
        InkWell(
          onTap: () => _showCharacterActions(context, character),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            character.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            character.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.touch_app,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCharacterDetails(character),
                const SizedBox(height: 8),
                // Tap hint
                const Text(
                  'Tap to edit character or add memories',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Character Memory Section
        CharacterMemoryWidget(character: character),
        const SizedBox(height: 24),

        // Usage Instructions
        _buildUsageInstructions(),
      ],
    );
  }

  Widget _buildCharacterDetails(CharacterEntity character) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (character.personality.isNotEmpty) ...[
          const Text(
            'Personality:',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            character.personality,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
        ],
        if (character.backstory.isNotEmpty) ...[
          const Text(
            'Backstory:',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            character.backstory,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
        ],
        if (character.speechPatterns.isNotEmpty) ...[
          const Text(
            'Speech Patterns:',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            character.speechPatterns,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildCreateCharacter(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 48, color: AppColors.primaryColor),
              const SizedBox(height: 16),
              const Text(
                'Create Your Character',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a character to use AI-powered @as commands in fellowship chats',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _showCharacterDialog(context, isEditing: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Create Character'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildUsageInstructions(),
      ],
    );
  }

  Widget _buildUsageInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'How to Use @as Commands',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'In fellowship chats, use @as commands to speak as your character:',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@as Gandalf "Welcome to my realm!"',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '@as "Sir Reginald" "Good day to you all!"',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI will generate responses based on your character\'s personality, memories, and chat context.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showCharacterActions(BuildContext context, CharacterEntity character) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.person_4, color: AppColors.primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    character.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose an action for your character',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Options
            _buildActionTile(
              context: bottomSheetContext,
              icon: Icons.edit,
              title: 'Edit Character',
              subtitle: 'Update personality, backstory, and details',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _populateForm(character);
                _showCharacterDialog(context, isEditing: true);
              },
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              context: bottomSheetContext,
              icon: Icons.auto_stories,
              title: 'Add Memory',
              subtitle: 'Add backstory, session notes, or character memories',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showAddMemoryDialog(context, character);
              },
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              context: bottomSheetContext,
              icon: Icons.info_outline,
              title: 'View Details',
              subtitle: 'See full character information',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showCharacterDetailsDialog(context, character);
              },
            ),
            
            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  void _showCharacterDialog(BuildContext context, {required bool isEditing}) {
    if (!isEditing) _clearForm();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: Text(
          isEditing ? 'Edit Character' : 'Create Character',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Character Name',
                    hint: 'e.g., Gandalf, Sir Reginald',
                    maxLength: 50,
                                      validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Character name is required';
                    }
                    return null;
                  },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Brief character description',
                    maxLength: 200,
                    maxLines: 2,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _personalityController,
                    label: 'Personality Traits',
                    hint: 'A wise and brave wizard with a mysterious past...',
                    maxLength: 300,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _backstoryController,
                    label: 'Backstory',
                    hint: 'Character background and history...',
                    maxLength: 1000,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _speechPatternsController,
                    label: 'Speech Patterns',
                    hint: 'Speaks formally with archaic language and poetic phrases...',
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _quotesController,
                    label: 'Favorite Quotes',
                    hint: 'You shall not pass!, Indeed, So it begins (comma-separated)',
                    maxLength: 500,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => _saveCharacter(context, dialogContext, isEditing),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.primaryColor),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        counterStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  void _saveCharacter(BuildContext context, BuildContext dialogContext, bool isEditing) {
    if (_formKey.currentState?.validate() != true) return;

    final userId = (context.read<AuthBloc>().state as AuthAuthenticated).user.id;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final personality = _personalityController.text.trim();
    final backstory = _backstoryController.text.trim();
    final speechPatterns = _speechPatternsController.text.trim();
    final quotes = _parseCommaSeparated(_quotesController.text);

    if (isEditing) {
      final characterId = (context.read<CharacterBloc>().state as CharacterLoaded).character.id;
      context.read<CharacterBloc>().add(UpdateCharacter(
        characterId: characterId,
        userId: userId,
        name: name,
        description: description,
        personality: personality,
        backstory: backstory,
        speechPatterns: speechPatterns,
        quotes: quotes,
      ));
    } else {
      context.read<CharacterBloc>().add(CreateCharacter(
        userId: userId,
        name: name,
        description: description,
        personality: personality,
        backstory: backstory,
        speechPatterns: speechPatterns,
        quotes: quotes,
      ));
    }

    Navigator.pop(dialogContext);
  }

  void _showAddMemoryDialog(BuildContext context, CharacterEntity character) {
    final memoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: Row(
          children: [
            const Icon(Icons.auto_stories, color: AppColors.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add Memory for ${character.name}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add backstory, session notes, or character memories to improve AI responses:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: memoryController,
                  maxLength: 1000,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary),
                                     validator: (value) {
                     if (value?.trim().isEmpty ?? true) {
                       return 'Memory content is required';
                     }
                     if (value!.trim().length < 10) {
                       return 'Memory should be at least 10 characters';
                     }
                     return null;
                   },
                  decoration: InputDecoration(
                    labelText: 'Memory Content',
                    hintText: 'e.g., "Defeated a dragon in the Crystal Caves during our last session..."',
                    labelStyle: const TextStyle(color: AppColors.primaryColor),
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                    ),
                    counterStyle: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
                         onPressed: () {
               if (formKey.currentState?.validate() == true) {
                // The CharacterMemoryWidget will handle adding the memory
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Use the Character Memory section below to add memories'),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Memory'),
          ),
        ],
      ),
    );
  }

  void _showCharacterDetailsDialog(BuildContext context, CharacterEntity character) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: Row(
          children: [
            const Icon(Icons.person_4, color: AppColors.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                character.name,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Description
                _buildDetailSection('Description', character.description),
                const SizedBox(height: 16),
                
                // Personality
                if (character.personality.isNotEmpty) ...[
                  _buildDetailSection('Personality', character.personality),
                  const SizedBox(height: 16),
                ],
                
                // Backstory
                if (character.backstory.isNotEmpty) ...[
                  _buildDetailSection('Backstory', character.backstory),
                  const SizedBox(height: 16),
                ],
                
                // Speech Patterns
                if (character.speechPatterns.isNotEmpty) ...[
                  _buildDetailSection('Speech Patterns', character.speechPatterns),
                  const SizedBox(height: 16),
                ],
                
                // Quotes
                if (character.quotes.isNotEmpty) ...[
                  _buildDetailSection('Favorite Quotes', character.quotes.join(', ')),
                  const SizedBox(height: 16),
                ],
                
                // Metadata
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Character Info',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Created: ${_formatDate(character.createdAt)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      'Last Updated: ${_formatDate(character.updatedAt)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      'Indexed for AI: ${character.isIndexed ? 'Yes' : 'No'}',
                      style: TextStyle(
                        color: character.isIndexed ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _populateForm(character);
              _showCharacterDialog(context, isEditing: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit Character'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
