import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/features/lfg/presentation/bloc/lfg_bloc.dart';
import 'package:critchat/features/lfg/presentation/bloc/lfg_event.dart';
import 'package:critchat/features/lfg/presentation/bloc/lfg_state.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';

class CreateLfgPostPage extends StatefulWidget {
  const CreateLfgPostPage({super.key});

  @override
  State<CreateLfgPostPage> createState() => _CreateLfgPostPageState();
}

class _CreateLfgPostPageState extends State<CreateLfgPostPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
  String _gameSystem = '';
  final List<String> _playStyles = [];
  String _sessionFormat = '';
  String _schedulePreference = '';
  String _campaignLength = '';
  final TextEditingController _callToAdventureController = TextEditingController();
  
  // Schedule input fields
  final TextEditingController _scheduleNumberController = TextEditingController();
  String _scheduleUnit = 'week';

  // Pre-defined options
  final List<String> _gameSystems = [
    'D&D 5e',
    'Pathfinder 2e',
    'Call of Cthulhu',
    'Vampire: The Masquerade',
    'Cosmere RPG',
    'Shadowrun',
    'World of Darkness',
    'Custom/Other',
  ];

  final List<String> _playStyleOptions = [
    'Combat-Heavy',
    'Roleplay-Focused',
    'Exploration',
    'Political Intrigue',
    'Puzzle-Solving',
    'Sandbox',
    'Tactical',
    'Magic-Heavy',
  ];

  final List<String> _sessionFormats = [
    'In-Person',
    'Online (Video/Voice)',
    'Semi-Asynchronous (through CritChat)',
    'Hybrid',
  ];

  final List<String> _scheduleUnits = [
    'day',
    'week', 
    'month',
    'year',
  ];

  final List<String> _campaignLengths = [
    'One-Shot',
    'Short Campaign',
    'Medium Campaign',
    'Long Campaign',
  ];

  @override
  void dispose() {
    _callToAdventureController.dispose();
    _scheduleNumberController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Call to Adventure'),
        centerTitle: true,
      ),
      body: BlocListener<LfgBloc, LfgState>(
        listener: (context, state) {
          if (state is LfgPostCreated) {
            Navigator.of(context).pop();
          } else if (state is LfgError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  for (int i = 0; i < 2; i++) ...[
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _currentPage 
                              ? AppColors.primaryColor 
                              : AppColors.primaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildDetailsStep(),
                  _buildCallToAdventureStep(),
                ],
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _currentPage == 1 ? _createPost : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(_currentPage == 1 ? 'Create Post' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Game System
          _buildSection(
            'Game System',
            _buildChipSelector(
              _gameSystems,
              _gameSystem,
              (value) => setState(() => _gameSystem = value),
              singleSelect: true,
            ),
          ),

          // Play Styles
          _buildSection(
            'Play Styles (Select all that apply)',
            _buildChipSelector(
              _playStyleOptions,
              _playStyles,
              (value) {
                setState(() {
                  if (_playStyles.contains(value)) {
                    _playStyles.remove(value);
                  } else {
                    _playStyles.add(value);
                  }
                });
              },
              singleSelect: false,
            ),
          ),

          // Session Format
          _buildSection(
            'Session Format',
            _buildChipSelector(
              _sessionFormats,
              _sessionFormat,
              (value) => setState(() => _sessionFormat = value),
              singleSelect: true,
            ),
          ),

          // Schedule
          _buildSection(
            'Schedule Preference',
            _buildScheduleInput(),
          ),

          // Campaign Length
          _buildSection(
            'Campaign Length',
            _buildChipSelector(
              _campaignLengths,
              _campaignLength,
              (value) => setState(() => _campaignLength = value),
              singleSelect: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallToAdventureStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Call to Adventure',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe what kind of experience you\'re looking for. This is what other players will see first!',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _callToAdventureController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'Example: Seeking fellow adventurers for an epic journey through the Forgotten Realms! Looking for players who love deep character development and collaborative storytelling...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.textSecondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildChipSelector(
    List<String> options,
    dynamic selected,
    Function(String) onSelected, {
    required bool singleSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = singleSelect 
            ? selected == option 
            : (selected as List<String>).contains(option);

        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          backgroundColor: AppColors.cardBackground,
          selectedColor: AppColors.primaryColor.withOpacity(0.2),
          checkmarkColor: AppColors.primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScheduleInput() {
    return Row(
      children: [
        // Number input
        Expanded(
          flex: 2,
          child: TextField(
            controller: _scheduleNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 1',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.textSecondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (value) {
              _updateSchedulePreference();
            },
          ),
        ),
        const SizedBox(width: 12),
        // "times /" text
        const Text(
          'times /',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        // Unit dropdown
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textSecondary),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.cardBackground,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _scheduleUnit,
                isExpanded: true,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: AppColors.textPrimary),
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                items: _scheduleUnits.map((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(
                      unit,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _scheduleUnit = newValue;
                      _updateSchedulePreference();
                    });
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateSchedulePreference() {
    final number = _scheduleNumberController.text.trim();
    if (number.isNotEmpty) {
      setState(() {
        _schedulePreference = '$number/$_scheduleUnit';
      });
    } else {
      setState(() {
        _schedulePreference = '';
      });
    }
  }

  void _nextPage() {
    if (_isCurrentPageValid()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showValidationError();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _isCurrentPageValid() {
    if (_currentPage == 0) {
      return _gameSystem.isNotEmpty &&
             _playStyles.isNotEmpty &&
             _sessionFormat.isNotEmpty &&
             _scheduleNumberController.text.trim().isNotEmpty &&
             _campaignLength.isNotEmpty;
    } else if (_currentPage == 1) {
      return _callToAdventureController.text.trim().isNotEmpty;
    }
    return false;
  }

  void _showValidationError() {
    String message = '';
    if (_currentPage == 0) {
      message = 'Please fill in all game details including schedule frequency before continuing.';
    } else if (_currentPage == 1) {
      message = 'Please write your Call to Adventure before creating the post.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _createPost() {
    if (!_isCurrentPageValid()) {
      _showValidationError();
      return;
    }

    // Ensure schedule preference is set from current input
    _updateSchedulePreference();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<LfgBloc>().add(
        CreateLfgPost(
          userId: authState.user.id,
          userName: authState.user.displayName ?? 'Anonymous',
          userLevel: authState.user.totalXp,
          gameSystem: _gameSystem,
          playStyles: _playStyles,
          sessionFormat: _sessionFormat,
          schedulePreference: _schedulePreference,
          campaignLength: _campaignLength,
          callToAdventureText: _callToAdventureController.text.trim(),
        ),
      );
    }
  }
} 