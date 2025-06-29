import 'package:flutter/material.dart';
import 'package:critchat/features/lfg/domain/entities/lfg_post_entity.dart';
import 'package:critchat/core/constants/app_colors.dart';

class LfgPostCard extends StatelessWidget {
  final LfgPostEntity post;
  final VoidCallback onExpressInterest;
  final String? currentUserId;

  const LfgPostCard({
    super.key,
    required this.post,
    required this.onExpressInterest,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and match score
            Row(
              children: [
                // User avatar (placeholder)
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  child: Text(
                    post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Level ${post.userLevel}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Match score if available
                if (post.matchScore != null && post.matchScore! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(post.matchScore! * 100).round()}% match',
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Game system and session format
            Row(
              children: [
                _buildTag(post.gameSystem, AppColors.primaryColor),
                const SizedBox(width: 8),
                _buildTag(post.sessionFormat, Colors.blue),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Play styles
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.playStyles.map((style) => 
                _buildTag(style, Colors.green.withOpacity(0.7))
              ).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Call to Adventure text
            Text(
              post.callToAdventureText,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 16),
            
            // Campaign details
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  post.schedulePreference,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.timeline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  post.campaignLength,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action row
            Row(
              children: [
                // Interest count
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.interestCount} interested',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Time posted
                Text(
                  _formatTimeAgo(post.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Express interest button
                _buildInterestButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestButton() {
    final hasExpressedInterest = currentUserId != null && 
        post.hasUserExpressedInterest(currentUserId!);
    
    if (hasExpressedInterest) {
      // User has already expressed interest - show "Call Answered!" and disable
      return ElevatedButton.icon(
        onPressed: null, // Disabled
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.withOpacity(0.8),
          disabledBackgroundColor: Colors.green.withOpacity(0.8),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          minimumSize: Size.zero,
        ),
        icon: const Icon(Icons.check_circle, size: 16),
        label: const Text(
          'Call Answered!',
          style: TextStyle(fontSize: 13),
        ),
      );
    } else {
      // User hasn't expressed interest - show "Answer Call" button
      return ElevatedButton.icon(
        onPressed: onExpressInterest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          minimumSize: Size.zero,
        ),
        icon: const Icon(Icons.campaign, size: 16),
        label: const Text(
          'Answer Call',
          style: TextStyle(fontSize: 13),
        ),
      );
    }
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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