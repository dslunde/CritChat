import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/friend_entity.dart';
import '../pages/friend_profile_page.dart';
import '../pages/chat_page.dart';

class FriendListItem extends StatelessWidget {
  final FriendEntity friend;

  const FriendListItem({super.key, required this.friend});

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendProfilePage(friend: friend),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(friend: friend)),
    );
  }

  void _showSnapComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Snap feature coming soon!'),
        backgroundColor: AppColors.primaryColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: friend.isOnline
                      ? AppColors.successColor
                      : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: friend.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        friend.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              color: AppColors.primaryColor,
                              size: 24,
                            ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Friend Info
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToProfile(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: friend.isOnline
                              ? AppColors.successColor
                              : AppColors.textSecondary.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        friend.isOnline ? 'Online' : _getLastSeenText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  if (friend.preferredSystems.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      friend.preferredSystems.take(2).join(', '),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chat Button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _openChat(context),
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: AppColors.primaryColor,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 8),

              // Snap Button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _showSnapComingSoon(context),
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    size: 18,
                    color: AppColors.primaryColor,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLastSeenText() {
    if (friend.lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(friend.lastSeen!);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
