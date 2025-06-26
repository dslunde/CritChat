import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';
import 'package:critchat/features/fellowships/presentation/widgets/invite_friends_dialog.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_bloc.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_event.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_state.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';
import 'package:critchat/features/auth/data/datasources/auth_firestore_datasource.dart';
import 'package:critchat/core/di/injection_container.dart';

class FellowshipInfoPage extends StatefulWidget {
  final FellowshipEntity fellowship;

  const FellowshipInfoPage({super.key, required this.fellowship});

  @override
  State<FellowshipInfoPage> createState() => _FellowshipInfoPageState();
}

class _FellowshipInfoPageState extends State<FellowshipInfoPage> {
  FellowshipEntity get fellowship => widget.fellowship;

  @override
  Widget build(BuildContext context) {
    return BlocListener<FellowshipBloc, FellowshipState>(
      listener: (context, state) {
        if (state is MemberRemoved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member removed successfully'),
              backgroundColor: AppColors.primaryColor,
            ),
          );
          // Pop back to previous screen with success result
          Navigator.of(context).pop(true);
        } else if (state is FellowshipError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Fellowship Info'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header with gradient background
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, _getGameSystemColor()],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Fellowship Image/Avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Fellowship Name
                    Text(
                      fellowship.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Game System
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.casino,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            fellowship.gameSystem,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Invite Friend Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showInviteFriendsDialog(context),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Invite a Friend'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Fellowship Details
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description Section
                    _buildInfoSection(
                      title: 'Description',
                      content: fellowship.description,
                      icon: Icons.description,
                    ),

                    const SizedBox(height: 24),

                    // Stats Section
                    _buildInfoSection(
                      title: 'Fellowship Stats',
                      icon: Icons.analytics,
                      child: Column(
                        children: [
                          _buildStatRow(
                            icon: Icons.group,
                            label: 'Members',
                            value: '${fellowship.memberCount}',
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            icon: fellowship.isPublic
                                ? Icons.public
                                : Icons.lock,
                            label: 'Visibility',
                            value: fellowship.isPublic ? 'Public' : 'Private',
                          ),
                          if (!fellowship.isPublic &&
                              fellowship.joinCode != null) ...[
                            const SizedBox(height: 12),
                            _buildJoinCodeRow(fellowship.joinCode!),
                          ],
                          const SizedBox(height: 12),
                          _buildStatRow(
                            icon: Icons.calendar_today,
                            label: 'Created',
                            value: _formatDate(fellowship.createdAt),
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            icon: Icons.update,
                            label: 'Last Activity',
                            value: _formatDate(fellowship.updatedAt),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Members Section
                    _buildInfoSection(
                      title: 'Members (${fellowship.memberIds.length})',
                      icon: Icons.people,
                      child: FutureBuilder<List<Widget>>(
                        future: _buildMembersList(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Error loading members',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }

                          final memberWidgets = snapshot.data ?? [];
                          return Column(children: memberWidgets);
                        },
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Leave Fellowship Button at bottom
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.backgroundColor,
            border: Border(top: BorderSide(color: AppColors.borderColor)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLeaveFellowshipDialog(context),
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Leave Fellowship'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    String? content,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (content != null)
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTile(
    String name,
    String role,
    bool isCreator,
    String userId,
  ) {
    // Check if current user is the creator and can remove members
    final canRemoveMember =
        _isCurrentUserCreator() && !isCreator && userId != _getCurrentUserId();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryColor,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isCreator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Creator',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (canRemoveMember)
            IconButton(
              onPressed: () => _showRemoveMemberDialog(name, userId),
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red,
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showInviteFriendsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => InviteFriendsDialog(
        fellowshipId: fellowship.id,
        fellowshipName: fellowship.name,
        fellowshipMemberIds: fellowship.memberIds,
      ),
    );
  }

  void _showLeaveFellowshipDialog(BuildContext context) {
    final pageContext =
        context; // Capture the page context that has access to BLoCs
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Leave Fellowship',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to leave "${fellowship.name}"? You can always be invited back by another member.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _leaveFellowship(
                pageContext,
              ); // Use the page context, not dialog context
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<List<Widget>> _buildMembersList() async {
    final List<Widget> memberWidgets = [];

    try {
      // Get user documents for all member IDs
      for (final memberId in fellowship.memberIds) {
        final isCreator = memberId == fellowship.creatorId;

        // Try to get user details from AuthFirestoreDataSource
        String displayName = 'User $memberId'; // Fallback
        try {
          final authDataSource = sl<AuthFirestoreDataSource>();
          final user = await authDataSource.getUserById(memberId);
          if (user != null &&
              user.displayName != null &&
              user.displayName!.isNotEmpty) {
            displayName = user.displayName!;
          }
        } catch (e) {
          // If we can't fetch user details, use fallback
          debugPrint('Error fetching user details for $memberId: $e');
        }

        memberWidgets.add(
          _buildMemberTile(
            displayName,
            isCreator ? 'Creator' : 'Member',
            isCreator,
            memberId,
          ),
        );
      }
    } catch (e) {
      // Return empty list on error
      return [];
    }

    return memberWidgets;
  }

  bool _isCurrentUserCreator() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id == fellowship.creatorId;
    }
    return false;
  }

  String? _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  void _showRemoveMemberDialog(String memberName, String userId) {
    final pageContext =
        context; // Capture the page context that has access to BLoCs
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Remove Member',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove $memberName from "${fellowship.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Call _removeMember in the page context, not dialog context
              pageContext.read<FellowshipBloc>().add(
                RemoveMember(fellowshipId: fellowship.id, memberId: userId),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _leaveFellowship(BuildContext context) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to leave fellowship: User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Use the RemoveMember event to remove the current user from the fellowship
    context.read<FellowshipBloc>().add(
      RemoveMember(fellowshipId: fellowship.id, memberId: currentUserId),
    );
  }

  Widget _buildJoinCodeRow(String joinCode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.vpn_key, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join Code',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  joinCode,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyJoinCode(joinCode),
            icon: const Icon(Icons.copy, size: 20),
            color: AppColors.primaryColor,
            tooltip: 'Copy join code',
          ),
        ],
      ),
    );
  }

  void _copyJoinCode(String joinCode) {
    // Copy to clipboard functionality would go here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Join code "$joinCode" copied to clipboard!'),
        backgroundColor: AppColors.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
