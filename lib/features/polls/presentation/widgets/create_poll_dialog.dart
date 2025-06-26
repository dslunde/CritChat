import 'package:flutter/material.dart';
import 'package:critchat/core/constants/app_colors.dart';

class CreatePollDialog extends StatefulWidget {
  final String fellowshipId;
  final Function(
    String title,
    String? description,
    String fellowshipId,
    DateTime expiresAt,
    bool allowCustomOptions,
    bool allowMultipleChoice,
    List<String> initialOptions,
  )
  onCreatePoll;

  const CreatePollDialog({
    super.key,
    required this.fellowshipId,
    required this.onCreatePoll,
  });

  @override
  State<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<CreatePollDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _allowCustomOptions = false;
  bool _allowMultipleChoice = false;
  int _selectedDuration = 24; // hours
  final List<int> _durationOptions = [1, 6, 12, 24, 48, 72, 168]; // hours

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.poll, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create Poll',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      _buildSectionTitle('Question'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: _buildInputDecoration(
                          'What would you like to ask?',
                          Icons.help_outline,
                        ),
                        style: const TextStyle(fontSize: 16),
                        maxLength: 200,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a question';
                          }
                          if (value.trim().length < 5) {
                            return 'Question must be at least 5 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Description (Optional)
                      _buildSectionTitle('Description (Optional)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _buildInputDecoration(
                          'Add more context to your poll...',
                          Icons.description_outlined,
                        ),
                        style: const TextStyle(fontSize: 14),
                        maxLines: 3,
                        maxLength: 500,
                      ),

                      const SizedBox(height: 16),

                      // Options
                      _buildSectionTitle('Answer Options'),
                      const SizedBox(height: 8),
                      ..._buildOptionFields(),

                      const SizedBox(height: 8),
                      _buildAddOptionButton(),

                      const SizedBox(height: 20),

                      // Duration
                      _buildSectionTitle('Poll Duration'),
                      const SizedBox(height: 8),
                      _buildDurationSelector(),

                      const SizedBox(height: 20),

                      // Settings
                      _buildSectionTitle('Poll Settings'),
                      const SizedBox(height: 8),
                      _buildSettingsToggles(),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.borderColor),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createPoll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Create Poll'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      fillColor: AppColors.backgroundColor.withValues(alpha: 0.5),
      filled: true,
    );
  }

  List<Widget> _buildOptionFields() {
    return _optionControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      final isRequired = index < 2;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: _buildInputDecoration(
                  'Option ${index + 1}${isRequired ? ' (required)' : ''}',
                  Icons.radio_button_unchecked,
                ),
                style: const TextStyle(fontSize: 14),
                maxLength: 100,
                validator: isRequired
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'This option is required';
                        }
                        return null;
                      }
                    : null,
              ),
            ),
            if (!isRequired) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeOption(index),
                icon: const Icon(
                  Icons.remove_circle,
                  color: AppColors.errorColor,
                ),
                tooltip: 'Remove option',
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildAddOptionButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _optionControllers.length < 10 ? _addOption : null,
        icon: const Icon(Icons.add, size: 18),
        label: Text(
          'Add Option (${_optionControllers.length}/10)',
          style: const TextStyle(fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          side: BorderSide(
            color: _optionControllers.length < 10
                ? AppColors.primaryColor
                : AppColors.textHint,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How long should this poll run?',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _durationOptions.map((hours) {
              final isSelected = _selectedDuration == hours;
              return ChoiceChip(
                label: Text(_formatDuration(hours)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedDuration = hours;
                    });
                  }
                },
                selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsToggles() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Allow multiple choices',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              'Users can select more than one option',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            value: _allowMultipleChoice,
            onChanged: (value) {
              setState(() {
                _allowMultipleChoice = value;
              });
            },
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text(
              'Allow custom options',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              'Users can add their own answer options',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            value: _allowCustomOptions,
            onChanged: (value) {
              setState(() {
                _allowCustomOptions = value;
              });
            },
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (index >= 2 && _optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  String _formatDuration(int hours) {
    if (hours < 24) {
      return '${hours}h';
    } else if (hours == 24) {
      return '1 day';
    } else if (hours == 168) {
      return '1 week';
    } else {
      return '${hours ~/ 24} days';
    }
  }

  void _createPoll() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get non-empty options
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least 2 answer options'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    // Check for duplicate options
    final uniqueOptions = options.toSet();
    if (uniqueOptions.length != options.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please remove duplicate answer options'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final expiresAt = DateTime.now().add(Duration(hours: _selectedDuration));

    widget.onCreatePoll(
      _titleController.text.trim(),
      _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      widget.fellowshipId,
      expiresAt,
      _allowCustomOptions,
      _allowMultipleChoice,
      options,
    );

    Navigator.pop(context);
  }
}
