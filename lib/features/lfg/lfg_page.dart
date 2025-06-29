import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/widgets/app_top_bar.dart';
import 'package:critchat/features/lfg/presentation/bloc/lfg_bloc.dart';
import 'package:critchat/features/lfg/presentation/bloc/lfg_event.dart';
import 'package:critchat/features/lfg/presentation/bloc/lfg_state.dart';
import 'package:critchat/features/lfg/presentation/widgets/lfg_post_card.dart';
import 'package:critchat/features/lfg/presentation/pages/create_lfg_post_page.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';


class LfgPage extends StatefulWidget {
  const LfgPage({super.key});

  @override
  State<LfgPage> createState() => _LfgPageState();
}

class _LfgPageState extends State<LfgPage> {
  @override
  void initState() {
    super.initState();
    _loadLfgPosts();
  }

  void _loadLfgPosts() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<LfgBloc>().add(LoadLfgPosts(currentUserId: authState.user.id));
    }
  }

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
                child: BlocConsumer<LfgBloc, LfgState>(
                  listener: (context, state) {
                    if (state is LfgError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (state is LfgPostCreated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.primaryColor,
                        ),
                      );
                      _loadLfgPosts(); // Refresh the feed
                    } else if (state is InterestExpressed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.primaryColor,
                        ),
                      );
                      _loadLfgPosts(); // Refresh the feed
                    }
                  },
                  builder: (context, state) {
                    if (state is LfgLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    }

                    if (state is LfgPostsLoaded) {
                      final posts = state.posts;

                      if (posts.isEmpty) {
                        return _buildEmptyState();
                      }

                      return RefreshIndicator(
                        color: AppColors.primaryColor,
                        onRefresh: () async {
                          _loadLfgPosts();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: LfgPostCard(
                                post: posts[index],
                                onExpressInterest: () => _expressInterest(posts[index].id),
                              ),
                            );
                          },
                        ),
                      );
                    }

                    // Initial state or error
                    return _buildEmptyState();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreatePost,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Call to Adventure',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              size: 80,
              color: AppColors.primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            const Text(
              'Looking for Group',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'No active LFG posts yet. Create your first Call to Adventure to find fellow players!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreatePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Create Your First Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<LfgBloc>(),
          child: const CreateLfgPostPage(),
        ),
      ),
    );
  }

  void _expressInterest(String postId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<LfgBloc>().add(
        ExpressInterest(
          postId: postId,
          userId: authState.user.id,
        ),
      );
    }
  }
}
