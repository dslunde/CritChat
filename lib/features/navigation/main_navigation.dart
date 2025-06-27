import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/core/gamification/gamification_service.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/lfg/lfg_page.dart';
import 'package:critchat/features/friends/friends_page.dart';
import 'package:critchat/features/home/home_page.dart';
import 'package:critchat/features/fellowships/presentation/pages/fellowships_page.dart';
import 'package:critchat/features/profile/for_me_page.dart';
import 'package:critchat/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:critchat/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:critchat/features/gamification/presentation/widgets/level_up_dialog.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2; // Start with Camera (home) page
  Timer? _levelUpCheckTimer;

  @override
  void initState() {
    super.initState();
    // Check for level-ups every 2 seconds
    _levelUpCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkForLevelUps(),
    );
  }

  @override
  void dispose() {
    _levelUpCheckTimer?.cancel();
    super.dispose();
  }

  void _checkForLevelUps() {
    final gamificationService = sl<GamificationService>();
    if (gamificationService.hasPendingLevelUp) {
      final levelUpData = gamificationService.getAndClearLevelUp();
      if (levelUpData != null && mounted) {
        _showLevelUpDialog(
          context,
          levelUpData.updatedXp,
          levelUpData.previousLevel,
          levelUpData.xpGained,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the AuthBloc from the context to pass it down
    final authBloc = context.read<AuthBloc>();

    final List<Widget> pages = [
      BlocProvider.value(value: authBloc, child: const LfgPage()),
      BlocProvider.value(value: authBloc, child: const FriendsPage()),
      BlocProvider.value(value: authBloc, child: const HomePage()),
      BlocProvider.value(value: authBloc, child: const FellowshipsPage()),
      BlocProvider.value(value: authBloc, child: const ForMePage()),
    ];

    return BlocProvider(
      create: (context) => sl<GamificationBloc>(),
      child: BlocListener<GamificationBloc, GamificationState>(
        listener: (context, state) {
          if (state is XpAwarded && state.leveledUp) {
            _showLevelUpDialog(
              context,
              state.xpEntity,
              state.xpEntity.currentLevel - 1, // Calculate previous level
              state.rewardType.xpAmount,
            );
          } else if (state is BatchXpAwarded && state.leveledUp) {
            final totalXp = state.rewardTypes.fold(
              0,
              (sum, reward) => sum + reward.xpAmount,
            );
            _showLevelUpDialog(
              context,
              state.xpEntity,
              state.xpEntity.currentLevel - 1, // Calculate previous level
              totalXp,
            );
          }
        },
        child: Scaffold(
          body: pages[_currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              border: Border(
                top: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.backgroundColor,
              selectedItemColor: AppColors.primaryColor,
              unselectedItemColor: AppColors.textSecondary,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 0,
              iconSize: 28,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_add_outlined),
                  activeIcon: Icon(Icons.group_add),
                  label: 'LFG',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Friends',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera_alt_outlined),
                  activeIcon: Icon(Icons.camera_alt),
                  label: 'Camera',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.groups_outlined),
                  activeIcon: Icon(Icons.groups),
                  label: 'Fellowships',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'For Me',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLevelUpDialog(
    BuildContext context,
    XpEntity xpEntity,
    int previousLevel,
    int xpGained,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelUpDialog(
        xpEntity: xpEntity,
        previousLevel: previousLevel,
        xpGained: xpGained,
      ),
    );
  }
}
