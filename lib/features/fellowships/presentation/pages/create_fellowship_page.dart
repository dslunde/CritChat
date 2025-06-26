import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/fellowship_bloc.dart';
import '../bloc/fellowship_event.dart';
import '../bloc/fellowship_state.dart';

class CreateFellowshipPage extends StatefulWidget {
  const CreateFellowshipPage({super.key});

  @override
  State<CreateFellowshipPage> createState() => _CreateFellowshipPageState();
}

class _CreateFellowshipPageState extends State<CreateFellowshipPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedGameSystem = 'D&D 5e';
  bool _isPublic = true;
  bool _isLoading = false;

  final List<String> _gameSystems = [
    'D&D 5e',
    'Pathfinder 2e',
    'Call of Cthulhu 7e',
    'Shadowrun 6e',
    'Vampire: The Masquerade 5e',
    'World of Darkness',
    'GURPS',
    'Savage Worlds',
    'Fate Core',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Fellowship'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: BlocListener<FellowshipBloc, FellowshipState>(
        listener: (context, state) {
          if (state is FellowshipLoading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);

            if (state is FellowshipCreated) {
              Navigator.of(context).pop();
            } else if (state is FellowshipError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Create a New Fellowship',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bring together your TTRPG party for epic adventures',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // Fellowship Name
                _buildSectionTitle('Fellowship Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                    hintText: 'The Brave Adventurers',
                    prefixIcon: Icons.group,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a fellowship name';
                    }
                    if (value.trim().length < 3) {
                      return 'Fellowship name must be at least 3 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Description
                _buildSectionTitle('Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: _buildInputDecoration(
                    hintText:
                        'Tell others about your campaign, play style, and what makes your fellowship special...',
                    prefixIcon: Icons.description,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Game System
                _buildSectionTitle('Game System'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedGameSystem,
                    decoration: _buildInputDecoration(
                      hintText: 'Select game system',
                      prefixIcon: Icons.casino,
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    items: _gameSystems.map((system) {
                      return DropdownMenuItem(
                        value: system,
                        child: Text(system),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGameSystem = value!;
                      });
                    },
                    dropdownColor: AppColors.cardBackground,
                  ),
                ),

                const SizedBox(height: 24),

                // Privacy Settings
                _buildSectionTitle('Privacy Settings'),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Public Fellowship',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          _isPublic
                              ? 'Others can discover and request to join your fellowship'
                              : 'Fellowship is private and invite-only',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        value: _isPublic,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createFellowship,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Create Fellowship',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Help Text
                Center(
                  child: Text(
                    'You can invite friends and manage members after creating your fellowship',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    bool filled = true,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(prefixIcon, color: AppColors.primaryColor),
      filled: filled,
      fillColor: fillColor ?? AppColors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _createFellowship() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<FellowshipBloc>().add(
          CreateFellowship(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            gameSystem: _selectedGameSystem,
            isPublic: _isPublic,
            creatorId: authState.user.id,
          ),
        );
      }
    }
  }
}
