import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/di/injection_container.dart';
import 'presentation/bloc/friends_bloc.dart';
import 'presentation/bloc/friends_event.dart';
import 'presentation/bloc/friends_state.dart';
import 'presentation/widgets/friend_list_item.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FriendsBloc>()..add(const LoadFriends()),
      child: Scaffold(
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
                  child: BlocBuilder<FriendsBloc, FriendsState>(
                    builder: (context, state) {
                      if (state is FriendsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        );
                      }

                      if (state is FriendsError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 80,
                                  color: AppColors.errorColor,
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Oops! Something went wrong',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  state.message,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<FriendsBloc>().add(
                                      const LoadFriends(),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state is FriendsEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 24),
                                Text(
                                  'No Friends Yet',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Start connecting with fellow adventurers to build your party!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state is FriendsLoaded) {
                        return Column(
                          children: [
                            // Header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Party',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${state.friends.length} adventurer${state.friends.length == 1 ? '' : 's'} in your network',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Friends List
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  context.read<FriendsBloc>().add(
                                    const RefreshFriends(),
                                  );
                                  // Wait a bit for the refresh to complete
                                  await Future.delayed(
                                    const Duration(milliseconds: 500),
                                  );
                                },
                                color: AppColors.primaryColor,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  itemCount: state.friends.length,
                                  itemBuilder: (context, index) {
                                    final friend = state.friends[index];
                                    return FriendListItem(friend: friend);
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // Default state (FriendsInitial)
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people,
                                size: 80,
                                color: AppColors.primaryColor,
                              ),
                              SizedBox(height: 24),
                              Text(
                                'Friends',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Connect with your TTRPG friends and party members.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
