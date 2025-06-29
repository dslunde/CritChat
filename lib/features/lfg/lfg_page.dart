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
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, authState) {
                            final currentUserId = authState is AuthAuthenticated 
                                ? authState.user.id 
                                : null;

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: LfgPostCard(
                                    post: posts[index],
                                    currentUserId: currentUserId,
                                    onExpressInterest: () => _expressInterest(posts[index].id),
                                  ),
                                );
                              },
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
            // Adventure-themed icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.explore,
                size: 60,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            
            // Main message
            const Text(
              'No Calls To Adventure Here!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Subtitle
            const Text(
              'Would you like to make one?',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Description
            const Text(
              'Start your journey by creating the first post.\nLet other adventurers know what epic quest awaits!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Prominent "Make the Call" button
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 300),
              child: ElevatedButton(
                onPressed: _navigateToCreatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primaryColor.withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.campaign,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Make the Call',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Secondary helpful text
            Text(
              'Your adventure starts here! 🎲',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreatePost() {
    // Get both bloc references before navigation to avoid context issues
    final lfgBloc = context.read<LfgBloc>();
    final authBloc = context.read<AuthBloc>();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: lfgBloc),
            BlocProvider.value(value: authBloc),
          ],
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
