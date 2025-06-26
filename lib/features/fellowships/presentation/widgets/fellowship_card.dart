import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/fellowship_entity.dart';
import '../bloc/fellowship_bloc.dart';
import '../bloc/fellowship_event.dart';
import 'invite_friends_dialog.dart';

class FellowshipCard extends StatelessWidget {
  final FellowshipEntity fellowship;

  const FellowshipCard({super.key, required this.fellowship});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Fellowship Icon with game system color
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getGameSystemColor(),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Fellowship Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fellowship.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.casino,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fellowship.gameSystem,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            fellowship.isPublic ? Icons.public : Icons.lock,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              fellowship.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.group,
                  label:
                      '${fellowship.memberCount} member${fellowship.memberCount == 1 ? '' : 's'}',
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.schedule,
                  label: _getTimeAgo(fellowship.updatedAt),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showInviteFriendsDialog(context),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Invite Friends'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: const BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openFellowship(context),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Open'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGameSystemColor() {
    switch (fellowship.gameSystem.toLowerCase()) {
      case 'd&d 5e':
      case 'dungeons & dragons 5e':
        return Colors.red;
      case 'pathfinder 2e':
        return Colors.orange;
      case 'call of cthulhu 7e':
        return Colors.deepPurple;
      case 'shadowrun 6e':
        return Colors.cyan;
      case 'vampire: the masquerade 5e':
        return Colors.deepOrange;
      default:
        return AppColors.primaryColor;
    }
  }

  String _getTimeAgo(DateTime updatedAt) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

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

  void _showInviteFriendsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => InviteFriendsDialog(
        fellowshipId: fellowship.id,
        fellowshipName: fellowship.name,
      ),
    );
  }

  void _openFellowship(BuildContext context) {
    // TODO: Navigate to fellowship detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${fellowship.name}...'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }
}
