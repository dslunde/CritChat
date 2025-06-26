import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/di/injection_container.dart';

import 'package:critchat/features/fellowships/presentation/bloc/fellowship_bloc.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_event.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_state.dart';

class SearchOpenFellowshipsPage extends StatelessWidget {
  final String userId;

  const SearchOpenFellowshipsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FellowshipBloc>()..add(GetPublicFellowships()),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Search Open Fellowships'),
          elevation: 0,
        ),
        body: BlocConsumer<FellowshipBloc, FellowshipState>(
          listener: (context, state) {
            if (state is FellowshipError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is FellowshipJoined) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.primaryColor,
                ),
              );
              Navigator.of(
                context,
              ).pop(true); // Return true to indicate success
            }
          },
          builder: (context, state) {
            if (state is FellowshipLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }

            if (state is PublicFellowshipsLoaded) {
              if (state.fellowships.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.public,
                          color: AppColors.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Open Fellowships',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${state.fellowships.length} available',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Fellowship List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: state.fellowships.length,
                      itemBuilder: (context, index) {
                        final fellowship = state.fellowships[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _OpenFellowshipCard(
                            fellowship: fellowship,
                            onJoin: () =>
                                _joinFellowship(context, fellowship.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Open Fellowships',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'There are currently no public fellowships available to join. Check back later or create your own!',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _joinFellowship(BuildContext context, String fellowshipId) {
    context.read<FellowshipBloc>().add(
      JoinPublicFellowship(fellowshipId: fellowshipId, userId: userId),
    );
  }
}

class _OpenFellowshipCard extends StatelessWidget {
  final fellowship;
  final VoidCallback onJoin;

  const _OpenFellowshipCard({required this.fellowship, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with game system and member count
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getGameSystemColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    fellowship.gameSystem,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.group,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${fellowship.memberCount} members',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Fellowship name
            Text(
              fellowship.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              fellowship.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Join button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onJoin,
                icon: const Icon(Icons.add),
                label: const Text('Join Fellowship'),
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
      ),
    );
  }

  Color _getGameSystemColor() {
    switch (fellowship.gameSystem.toLowerCase()) {
      case 'd&d 5e':
      case 'dungeons & dragons':
        return const Color(0xFFE74C3C);
      case 'pathfinder':
        return const Color(0xFF8E44AD);
      case 'call of cthulhu':
        return const Color(0xFF2C3E50);
      case 'vampire: the masquerade':
        return const Color(0xFF8B0000);
      case 'shadowrun':
        return const Color(0xFF34495E);
      case 'world of darkness':
        return const Color(0xFF2C2C2C);
      default:
        return AppColors.primaryColor;
    }
  }
}
