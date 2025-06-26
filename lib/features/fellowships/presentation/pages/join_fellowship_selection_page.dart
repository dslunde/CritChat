import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_bloc.dart';
import 'package:critchat/features/fellowships/presentation/pages/search_open_fellowships_page.dart';
import 'package:critchat/features/fellowships/presentation/pages/join_fellowship_page.dart';

class JoinFellowshipSelectionPage extends StatelessWidget {
  final String userId;

  const JoinFellowshipSelectionPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Join Fellowship'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top -
                  48, // Account for padding
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),

                // Header
                Icon(
                  Icons.diversity_3,
                  size: 100,
                  color: AppColors.primaryColor.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Join a Fellowship',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose how you\'d like to join a fellowship and start your next adventure.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Search Open Groups Option
                _buildOptionCard(
                  context: context,
                  icon: Icons.search,
                  title: 'Search Open Fellowships',
                  subtitle:
                      'Browse and join public fellowships that welcome new members',
                  color: const Color(0xFF4CAF50),
                  onTap: () => _navigateToSearchOpen(context),
                ),

                const SizedBox(height: 24),

                // Enter Join Code Option
                _buildOptionCard(
                  context: context,
                  icon: Icons.vpn_key,
                  title: 'Enter Join Code',
                  subtitle:
                      'Join a private fellowship using a fellowship name and join code',
                  color: const Color(0xFF2196F3),
                  onTap: () => _navigateToJoinByCode(context),
                ),

                const SizedBox(height: 48),

                // Help text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Need help?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Public fellowships are open to everyone, while private fellowships require an invitation or join code from the creator.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Arrow
            Icon(Icons.arrow_forward, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  void _navigateToSearchOpen(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchOpenFellowshipsPage(userId: userId),
      ),
    );

    if (result == true && context.mounted) {
      Navigator.of(context).pop(true); // Pass success back to fellowships page
    }
  }

  void _navigateToJoinByCode(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => sl<FellowshipBloc>(),
          child: JoinFellowshipPage(userId: userId),
        ),
      ),
    );

    if (result == true && context.mounted) {
      Navigator.of(context).pop(true); // Pass success back to fellowships page
    }
  }
}
