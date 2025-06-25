import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_top_bar.dart';

class LfgPage extends StatelessWidget {
  const LfgPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar - Primary color
            const AppTopBar(backgroundColor: AppColors.primaryColor),

            // Content Area
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.backgroundColor,
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_add,
                          size: 80,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Looking for Group',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Find new campaigns and players to join your TTRPG adventures.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Coming Soon!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
