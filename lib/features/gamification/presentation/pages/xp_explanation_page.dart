import 'package:flutter/material.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';

class XpExplanationPage extends StatelessWidget {
  const XpExplanationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('How to Earn XP'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Header
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Earn Experience Points',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Level up by engaging with the CritChat community!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // XP Activities Section
            const Text(
              'XP Activities',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Social Activities
            _buildXpCategory(
              'Social & Community',
              Icons.people,
              [
                _XpActivity('Send Messages', XpRewardType.sendMessage.xpAmount),
                _XpActivity('Add Friends', XpRewardType.acceptFriendRequest.xpAmount),
                _XpActivity('First Message Bonus', XpRewardType.firstMessage.xpAmount),
              ],
            ),

            const SizedBox(height: 24),

            // Fellowship Activities
            _buildXpCategory(
              'Fellowship Adventures',
              Icons.groups,
              [
                _XpActivity('Create Fellowship', XpRewardType.createFellowship.xpAmount),
                _XpActivity('Join Fellowship', XpRewardType.joinFellowship.xpAmount),
                _XpActivity('Invite Friends', XpRewardType.inviteFriend.xpAmount),
                _XpActivity('First Fellowship Bonus', XpRewardType.firstFellowship.xpAmount),
              ],
            ),

            const SizedBox(height: 24),

            // LFG Activities
            _buildXpCategory(
              'Looking for Group',
              Icons.group_add,
              [
                _XpActivity('Create LFG Post', XpRewardType.lfgPostCreated.xpAmount),
                _XpActivity('Express Interest', XpRewardType.expressInterest.xpAmount),
              ],
            ),

            const SizedBox(height: 24),

            // Poll Activities
            _buildXpCategory(
              'Polls & Engagement',
              Icons.poll,
              [
                _XpActivity('Create Poll', XpRewardType.createPoll.xpAmount),
                _XpActivity('Vote on Poll', XpRewardType.voteOnPoll.xpAmount),
                _XpActivity('Add Poll Option', XpRewardType.addCustomOption.xpAmount),
                _XpActivity('First Poll Bonus', XpRewardType.firstPoll.xpAmount),
              ],
            ),

            const SizedBox(height: 24),

            // Setup Activities
            _buildXpCategory(
              'Getting Started',
              Icons.settings,
              [
                _XpActivity('Sign Up', XpRewardType.signUp.xpAmount),
                _XpActivity('Complete Profile', XpRewardType.completeProfile.xpAmount),
              ],
            ),

            const SizedBox(height: 32),

            // Tips Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pro Tips',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Stay active to unlock weekly and monthly bonuses\n'
                    '• First-time actions give bonus XP\n'
                    '• Engage with fellowships for the highest rewards\n'
                    '• Help others by answering LFG calls',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildXpCategory(String title, IconData icon, List<_XpActivity> activities) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activities.map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${activity.xpAmount} XP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _XpActivity {
  final String name;
  final int xpAmount;

  _XpActivity(this.name, this.xpAmount);
} 