import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/widgets/app_top_bar.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/core/gamification/gamification_service.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/gamification/presentation/widgets/xp_progress_widget.dart';

class ForMePage extends StatelessWidget {
  const ForMePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar - Primary color
            const AppTopBar(backgroundColor: AppColors.primaryColor),

            // Content Area
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.backgroundColor,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person,
                              size: 80,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'For Me',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (state is AuthAuthenticated) ...[
                              Text(
                                'Welcome, ${state.user.displayName ?? 'Adventurer'}!',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              // XP Progress Section
                              StreamBuilder<XpEntity>(
                                stream: sl<GamificationService>()
                                    .getCurrentUserXpStream(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Column(
                                      children: [
                                        XpProgressWidget(
                                          xpEntity: snapshot.data!,
                                          showLabel: true,
                                          compact: false,
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                            const Text(
                              'Your personal space for TTRPG content and settings.',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Coming Soon!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
