import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/core/utils/join_code_generator.dart';

import 'package:critchat/features/fellowships/presentation/bloc/fellowship_bloc.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_event.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_state.dart';

class JoinFellowshipPage extends StatefulWidget {
  final String userId;

  const JoinFellowshipPage({super.key, required this.userId});

  @override
  State<JoinFellowshipPage> createState() => _JoinFellowshipPageState();
}

class _JoinFellowshipPageState extends State<JoinFellowshipPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _joinCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _joinCodeController.dispose();
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
        title: const Text('Join Fellowship'),
        elevation: 0,
      ),
      body: BlocConsumer<FellowshipBloc, FellowshipState>(
        listener: (context, state) {
          if (state is FellowshipLoading) {
            setState(() {
              _isLoading = true;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }

          if (state is FellowshipError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is FellowshipJoined) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.primaryColor,
              ),
            );
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.key,
                    size: 80,
                    color: AppColors.primaryColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Join with Code',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter the fellowship name and join code to become a member.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  Text(
                    'Fellowship Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter the exact fellowship name',
                      prefixIcon: const Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Fellowship name is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Join Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _joinCodeController,
                    decoration: InputDecoration(
                      hintText: 'ABC-123',
                      prefixIcon: const Icon(Icons.vpn_key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      final normalized = JoinCodeGenerator.normalize(value);
                      if (normalized != value) {
                        _joinCodeController.value = TextEditingValue(
                          text: normalized,
                          selection: TextSelection.collapsed(
                            offset: normalized.length,
                          ),
                        );
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Join code is required';
                      }
                      if (!JoinCodeGenerator.isValidFormat(value.trim())) {
                        return 'Join code must be in format ABC-123';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _joinFellowship,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        _isLoading ? 'Joining...' : 'Join Fellowship',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _joinFellowship() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<FellowshipBloc>().add(
      JoinFellowshipByCode(
        name: _nameController.text.trim(),
        joinCode: _joinCodeController.text.trim(),
        userId: widget.userId,
      ),
    );
  }
}
