import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/widgets/app_top_bar.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_bloc.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_event.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_state.dart';
import 'package:critchat/features/fellowships/presentation/widgets/fellowship_card.dart';
import 'create_fellowship_page.dart';
import 'join_fellowship_selection_page.dart';

class FellowshipsPage extends StatelessWidget {
  const FellowshipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FellowshipBloc>()..add(GetFellowships()),
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
                  child: BlocConsumer<FellowshipBloc, FellowshipState>(
                    listener: (context, state) {
                      if (state is FellowshipError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (state is FellowshipCreated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fellowship created successfully!'),
                            backgroundColor: AppColors.primaryColor,
                          ),
                        );
                      } else if (state is FriendInvited) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Friend invited successfully!'),
                            backgroundColor: AppColors.primaryColor,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is FellowshipLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        );
                      }

                      if (state is FellowshipLoaded) {
                        if (state.fellowships.isEmpty) {
                          return _buildEmptyState(context);
                        }

                        return Column(
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.group,
                                    color: AppColors.primaryColor,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'My Fellowships',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _navigateToJoinFellowships(context),
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 16,
                                    ),
                                    label: const Text('Join'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryColor,
                                      side: const BorderSide(
                                        color: AppColors.primaryColor,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Fellowship List
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                itemCount: state.fellowships.length,
                                itemBuilder: (context, index) {
                                  final fellowship = state.fellowships[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    child: FellowshipCard(
                                      fellowship: fellowship,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      // Initial state or other states
                      return _buildEmptyState(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToCreateFellowship(context),
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              size: 80,
              color: AppColors.primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Fellowships Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Create your first fellowship to start organizing your TTRPG campaigns and adventures with friends.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _navigateToCreateFellowship(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Fellowship'),
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
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _navigateToFindFellowships(context),
                  icon: const Icon(Icons.search),
                  label: const Text('Find Open Fellowships'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    side: const BorderSide(color: AppColors.primaryColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  void _navigateToCreateFellowship(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (newContext) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => sl<FellowshipBloc>()),
            BlocProvider(create: (context) => sl<AuthBloc>()),
          ],
          child: const CreateFellowshipPage(),
        ),
      ),
    );

    // If fellowship was created successfully, reload the list
    if (result == true && context.mounted) {
      context.read<FellowshipBloc>().add(GetFellowships());
    }
  }

  void _navigateToFindFellowships(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              JoinFellowshipSelectionPage(userId: authState.user.id),
        ),
      );

      // If fellowship was joined successfully, reload the list
      if (result == true && context.mounted) {
        context.read<FellowshipBloc>().add(GetFellowships());
      }
    } else {
      // Show error if not authenticated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to join fellowships.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToJoinFellowships(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              JoinFellowshipSelectionPage(userId: authState.user.id),
        ),
      );

      // If fellowship was joined successfully, reload the list
      if (result == true && context.mounted) {
        context.read<FellowshipBloc>().add(GetFellowships());
      }
    } else {
      // Show error if not authenticated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to join fellowships.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
