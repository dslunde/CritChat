import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/constants/app_strings.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_event.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';
import 'package:critchat/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:critchat/features/auth/presentation/widgets/auth_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  String _selectedExperienceLevel = AppStrings.beginner;
  final List<String> _selectedSystems = [];

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onCompletePressed() {
    if (_displayNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a display name'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (_selectedSystems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one TTRPG system'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthOnboardingCompleted(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        preferredSystems: _selectedSystems,
        experienceLevel: _selectedExperienceLevel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorColor,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Welcome Text
                Text(
                  AppStrings.tellUsAboutYou,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Display Name Field
                AuthTextField(
                  controller: _displayNameController,
                  labelText: AppStrings.displayName,
                ),
                const SizedBox(height: 16),

                // Bio Field
                AuthTextField(
                  controller: _bioController,
                  labelText: AppStrings.bio,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Experience Level
                Text(
                  AppStrings.experienceLevel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children:
                      [
                        AppStrings.beginner,
                        AppStrings.intermediate,
                        AppStrings.experienced,
                        AppStrings.veteran,
                      ].map((level) {
                        return ChoiceChip(
                          label: Text(level),
                          selected: _selectedExperienceLevel == level,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedExperienceLevel = level;
                              });
                            }
                          },
                          selectedColor: AppColors.primaryColor.withValues(
                            alpha: 0.2,
                          ),
                          labelStyle: TextStyle(
                            color: _selectedExperienceLevel == level
                                ? AppColors.primaryColor
                                : AppColors.textSecondary,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),

                // Preferred Systems
                Text(
                  AppStrings.preferredSystems,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppStrings.commonSystems.map((system) {
                    final isSelected = _selectedSystems.contains(system);
                    return FilterChip(
                      label: Text(system),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSystems.add(system);
                          } else {
                            _selectedSystems.remove(system);
                          }
                        });
                      },
                      selectedColor: AppColors.primaryColor.withValues(
                        alpha: 0.2,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.textSecondary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),

                // Complete Button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return AuthButton(
                      text: AppStrings.completeProfile,
                      onPressed: _onCompletePressed,
                      isLoading: state is AuthLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
