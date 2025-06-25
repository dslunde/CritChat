import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class GoodbyePage extends StatefulWidget {
  const GoodbyePage({super.key});

  @override
  State<GoodbyePage> createState() => _GoodbyePageState();
}

class _GoodbyePageState extends State<GoodbyePage> {
  @override
  void initState() {
    super.initState();
    // Wait 3 seconds then trigger auth restart to go to login
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthStarted());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Farewell Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.waving_hand,
                  size: 60,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // Farewell Message
              const Text(
                'Happy Adventuring!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Thanks for using ${AppStrings.appName}',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              const Text(
                'May your dice roll high! 🎲',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Returning to login...',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
