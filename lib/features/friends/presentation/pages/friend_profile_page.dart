import 'package:flutter/material.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/features/friends/domain/entities/friend_entity.dart';
import 'chat_page.dart';

class FriendProfilePage extends StatelessWidget {
  final FriendEntity friend;

  const FriendProfilePage({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(friend.displayName),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: friend.isOnline
                            ? AppColors.successColor
                            : Colors.white70,
                        width: 3,
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
                                    color: Colors.white,
                                    size: 48,
                                  ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 48,
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Name and Status
                  Text(
                    friend.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: friend.isOnline
                              ? AppColors.successColor
                              : Colors.white70,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        friend.isOnline ? 'Online' : _getLastSeenText(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio Section
                  if (friend.bio != null && friend.bio!.isNotEmpty) ...[
                    _buildSectionTitle('About'),
                    _buildInfoCard(
                      icon: Icons.person_outline,
                      content: friend.bio!,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Experience Level
                  if (friend.experienceLevel != null) ...[
                    _buildSectionTitle('Experience Level'),
                    _buildInfoCard(
                      icon: Icons.star_outline,
                      content: _formatExperienceLevel(friend.experienceLevel!),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Preferred Systems
                  if (friend.preferredSystems.isNotEmpty) ...[
                    _buildSectionTitle('Preferred TTRPG Systems'),
                    _buildInfoCard(
                      icon: Icons.games_outlined,
                      content: friend.preferredSystems.join(', '),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // XP Stats
                  _buildSectionTitle('Adventure Stats'),
                  _buildInfoCard(
                    icon: Icons.emoji_events_outlined,
                    content: '${friend.totalXp} Total XP',
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToChat(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Message'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Snap feature coming soon!'),
                                backgroundColor: AppColors.primaryColor,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryColor,
                            foregroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Snap'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatExperienceLevel(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return 'Beginner - New to TTRPGs';
      case 'intermediate':
        return 'Intermediate - Some experience';
      case 'experienced':
        return 'Experienced - Regular player';
      case 'veteran':
        return 'Veteran - Years of experience';
      default:
        return level;
    }
  }

  String _getLastSeenText() {
    if (friend.lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(friend.lastSeen!);

    if (difference.inDays > 0) {
      return 'Last seen ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return 'Last seen ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return 'Last seen ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Last seen just now';
    }
  }

  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(friend: friend)),
    );
  }
}
