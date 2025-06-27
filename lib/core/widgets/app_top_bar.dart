import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/core/gamification/gamification_service.dart';
import 'package:critchat/core/services/notification_indicator_service.dart';
import 'package:critchat/core/widgets/notification_indicator.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';
import 'package:critchat/features/notifications/notifications_page.dart';
import 'package:critchat/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:critchat/features/profile/profile_page.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';

class AppTopBar extends StatelessWidget {
  final Color? backgroundColor;

  const AppTopBar({super.key, this.backgroundColor});

  void _navigateToProfile(BuildContext context) {
    // Get the AuthBloc instance before navigation
    final authBloc = context.read<AuthBloc>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BlocProvider.value(value: authBloc, child: const ProfilePage()),
      ),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    // Get the NotificationsBloc instance before navigation
    final notificationsBloc = context.read<NotificationsBloc>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: notificationsBloc,
          child: const NotificationsPage(),
        ),
      ),
    );
  }

  void _onSearchTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Search functionality coming soon!'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: backgroundColor ?? Colors.transparent),
      child: Row(
        children: [
          // Profile Portrait
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return GestureDetector(
                onTap: () => _navigateToProfile(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),

          // Search Bar
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _onSearchTap(context),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        MediaQuery.of(context).size.width > 350
                            ? 'Search CritChat...'
                            : 'Search...',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),
          // XP Progress Widget - constrained to avoid overflow
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                final gamificationService = sl<GamificationService>();
                return StreamBuilder<XpEntity>(
                  stream: gamificationService.getCurrentUserXpStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildMiniXpWidget(snapshot.data!);
                    }
                    return const SizedBox.shrink();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(width: 8),

          // Notifications Button with Red Dot Indicator
          StreamNotificationIndicator(
            countStream:
                sl<NotificationIndicatorService>().unreadNotificationsStream,
            size: 12,
            offset: const EdgeInsets.only(top: 2, right: 2),
            child: GestureDetector(
              onTap: () => _navigateToNotifications(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniXpWidget(XpEntity xpEntity) {
    return Container(
      width: 50, // Fixed width to prevent overflow
      height: 24, // Fixed height
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${xpEntity.currentLevel}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: xpEntity.progressToNextLevel,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
