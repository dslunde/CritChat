import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/features/polls/presentation/bloc/poll_bloc.dart';
import 'package:critchat/features/polls/presentation/bloc/poll_event.dart';
import 'package:critchat/features/polls/presentation/bloc/poll_state.dart';
import 'package:critchat/features/polls/presentation/widgets/poll_card.dart';
import 'package:critchat/features/polls/presentation/widgets/create_poll_dialog.dart';
import 'package:critchat/features/polls/domain/entities/poll_entity.dart';

class FellowshipPollsPage extends StatefulWidget {
  final String fellowshipId;
  final String fellowshipName;

  const FellowshipPollsPage({
    super.key,
    required this.fellowshipId,
    required this.fellowshipName,
  });

  @override
  State<FellowshipPollsPage> createState() => _FellowshipPollsPageState();
}

class _FellowshipPollsPageState extends State<FellowshipPollsPage> {
  late PollBloc _pollBloc;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _pollBloc = sl<PollBloc>();
    _pollBloc.add(GetFellowshipPolls(fellowshipId: widget.fellowshipId));
  }

  @override
  void dispose() {
    _pollBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _pollBloc,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: BlocConsumer<PollBloc, PollState>(
          listener: (context, state) {
            if (state is PollError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorColor,
                ),
              );
            } else if (state is PollCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Poll created successfully!'),
                  backgroundColor: AppColors.successColor,
                ),
              );
            } else if (state is PollVoteSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vote recorded!'),
                  backgroundColor: AppColors.successColor,
                  duration: Duration(seconds: 1),
                ),
              );
            } else if (state is PollOptionAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Option added successfully!'),
                  backgroundColor: AppColors.successColor,
                  duration: Duration(seconds: 1),
                ),
              );
            } else if (state is PollClosed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Poll closed'),
                  backgroundColor: AppColors.warningColor,
                  duration: Duration(seconds: 1),
                ),
              );
            } else if (state is PollDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Poll deleted'),
                  backgroundColor: AppColors.textSecondary,
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is PollLoading && state is! PollsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            // Get polls from either PollsLoaded or PollStateWithData
            List<PollEntity>? polls;
            if (state is PollsLoaded) {
              polls = state.polls;
            } else if (state is PollStateWithData) {
              polls = state.polls;
            } else if (state is PollError && state.polls != null) {
              polls = state.polls;
            }

            if (polls != null) {
              if (polls.isEmpty) {
                return _buildEmptyState();
              }

              // Sort polls: active first, then by creation date (newest first)
              final sortedPolls = List.from(polls)
                ..sort((a, b) {
                  // Active polls first
                  if (!a.isExpired && b.isExpired) return -1;
                  if (a.isExpired && !b.isExpired) return 1;

                  // Then by creation date (newest first)
                  return b.createdAt.compareTo(a.createdAt);
                });

              return RefreshIndicator(
                onRefresh: _refreshPolls,
                color: AppColors.primaryColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedPolls.length,
                  itemBuilder: (context, index) {
                    final poll = sortedPolls[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: PollCard(
                        poll: poll,
                        currentUserId: _auth.currentUser?.uid ?? '',
                        onVote: _handleVote,
                        onAddCustomOption: _handleAddCustomOption,
                        onClosePoll: _handleClosePoll,
                        onDeletePoll: _handleDeletePoll,
                        onRemoveVote: _handleRemoveVote,
                      ),
                    );
                  },
                ),
              );
            }

            if (state is PollError) {
              return _buildErrorState(state.message);
            }

            return _buildEmptyState();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreatePollDialog,
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          tooltip: 'Create Poll',
          child: const Icon(Icons.poll),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.poll, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No polls yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create the first poll for ${widget.fellowshipName}!',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreatePollDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Poll'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading polls',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.errorColor),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshPolls,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePollDialog() {
    showDialog(
      context: context,
      builder: (context) => CreatePollDialog(
        fellowshipId: widget.fellowshipId,
        onCreatePoll: _handleCreatePoll,
      ),
    );
  }

  void _handleCreatePoll(
    String title,
    String? description,
    String fellowshipId,
    DateTime expiresAt,
    bool allowCustomOptions,
    bool allowMultipleChoice,
    List<String> initialOptions,
  ) {
    _pollBloc.add(
      CreatePoll(
        title: title,
        description: description,
        fellowshipId: fellowshipId,
        expiresAt: expiresAt,
        allowCustomOptions: allowCustomOptions,
        allowMultipleChoice: allowMultipleChoice,
        initialOptions: initialOptions,
      ),
    );
  }

  void _handleVote(String pollId, List<String> optionIds) {
    _pollBloc.add(
      VoteOnPoll(
        pollId: pollId,
        optionIds: optionIds,
        fellowshipId: widget.fellowshipId,
      ),
    );
  }

  void _handleAddCustomOption(String pollId, String optionText) {
    _pollBloc.add(AddCustomOption(pollId: pollId, optionText: optionText));
  }

  void _handleClosePoll(String pollId) {
    _pollBloc.add(ClosePoll(pollId: pollId));
  }

  void _handleDeletePoll(String pollId) {
    _pollBloc.add(DeletePoll(pollId: pollId));
  }

  void _handleRemoveVote(String pollId) {
    _pollBloc.add(RemoveVote(pollId: pollId));
  }

  Future<void> _refreshPolls() async {
    _pollBloc.add(GetFellowshipPolls(fellowshipId: widget.fellowshipId));
  }
}
