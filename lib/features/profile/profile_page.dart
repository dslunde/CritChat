import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/core/gamification/gamification_service.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_event.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';
import 'package:critchat/features/friends/presentation/pages/search_friends_page.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/gamification/presentation/widgets/xp_progress_widget.dart';
import 'package:critchat/features/fellowships/presentation/pages/join_fellowship_selection_page.dart';
import 'package:critchat/features/navigation/main_navigation.dart';
import 'package:critchat/features/gamification/presentation/pages/xp_explanation_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Auto-pop when signing out to prevent old profile page from showing
        if (state is AuthSigningOut) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Welcome Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Welcome Text
                  const Text(
                    'Welcome to CritChat!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // User Info
                  if (state is AuthAuthenticated) ...[
                    Text(
                      'Hello, ${state.user.displayName ?? 'Adventurer'}!',
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.user.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Experience Level & Systems
                    if (state.user.experienceLevel != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${state.user.experienceLevel} Player',
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (state.user.preferredSystems.isNotEmpty) ...[
                      Text(
                        'Favorite Systems: ${state.user.preferredSystems.take(3).join(', ')}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],

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

                  // Status Message
                  const Text(
                    'Your TTRPG social app is ready to roll!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToSearchFriends(context),
                          icon: const Icon(Icons.person_search),
                          label: const Text('Find Friends'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToJoinFellowship(context),
                          icon: const Icon(Icons.diversity_3),
                          label: const Text('Join Fellowship'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToLfg(context),
                          icon: const Icon(Icons.group_add),
                          label: const Text('Looking For Group'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToXpExplanation(context),
                          icon: const Icon(Icons.star),
                          label: const Text('Earn XP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showLogoutDialog(context),
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorColor,
                            side: const BorderSide(color: AppColors.errorColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24), // Extra bottom padding
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToSearchFriends(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SearchFriendsPage()));
  }

  void _navigateToJoinFellowship(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => JoinFellowshipSelectionPage(userId: authState.user.id),
        ),
      );
    }
  }

  void _navigateToLfg(BuildContext context) {
    // Get the AuthBloc from current context to pass it to MainNavigation
    final authBloc = context.read<AuthBloc>();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: authBloc,
          child: const MainNavigation(initialIndex: 0), // LFG tab is at index 0
        ),
      ),
    );
  }

  void _navigateToXpExplanation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const XpExplanationPage(),
      ),
    );
  }
}
