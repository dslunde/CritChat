import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/features/polls/domain/entities/poll_entity.dart';

class PollCard extends StatefulWidget {
  final PollEntity poll;
  final String currentUserId;
  final Function(String pollId, List<String> optionIds) onVote;
  final Function(String pollId, String optionText) onAddCustomOption;
  final Function(String pollId) onClosePoll;
  final Function(String pollId) onDeletePoll;
  final Function(String pollId) onRemoveVote;

  const PollCard({
    super.key,
    required this.poll,
    required this.currentUserId,
    required this.onVote,
    required this.onAddCustomOption,
    required this.onClosePoll,
    required this.onDeletePoll,
    required this.onRemoveVote,
  });

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _customOptionController = TextEditingController();
  bool _showCustomOptionInput = false;
  Set<String> _selectedOptions = {};
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize selected options if user has voted
    if (widget.poll.hasUserVoted(widget.currentUserId)) {
      _selectedOptions = Set<String>.from(
        widget.poll.votes[widget.currentUserId] ?? [],
      );
    }

    // Auto-collapse expired polls
    _isCollapsed = widget.poll.isExpired;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _customOptionController.dispose();
    super.dispose();
  }

  void _triggerPulse() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  Color _getBorderColor() {
    if (widget.poll.isExpired) {
      return AppColors.textHint; // Gray for expired
    } else if (widget.poll.hasUserVoted(widget.currentUserId)) {
      return AppColors.primaryColor.withValues(
        alpha: 0.6,
      ); // Muted primary for voted
    } else {
      return AppColors.primaryColor; // Bold primary for unvoted active
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _getBorderColor(), width: 2),
            ),
            color: AppColors.cardBackground,
            child: GestureDetector(
              onLongPress: _showPollOptions,
              onTap: widget.poll.isExpired ? _toggleCollapse : null,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPollHeader(),
                    if (!_isCollapsed) ...[
                      const SizedBox(height: 12),
                      if (widget.poll.description != null) ...[
                        Text(
                          widget.poll.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildPollOptions(),
                      const SizedBox(height: 16),
                      _buildPollFooter(),
                      if (_showCustomOptionInput) ...[
                        const SizedBox(height: 12),
                        _buildCustomOptionInput(),
                      ],
                    ] else ...[
                      const SizedBox(height: 8),
                      _buildCollapsedResults(),
                      const SizedBox(height: 8),
                      _buildExpandHint(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPollHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.poll.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'by ${widget.poll.creatorName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;
    IconData statusIcon;

    if (widget.poll.isExpired) {
      chipColor = AppColors.textHint;
      statusText = 'Expired';
      statusIcon = Icons.schedule;
    } else if (widget.poll.hasUserVoted(widget.currentUserId)) {
      chipColor = AppColors.successColor;
      statusText = 'Voted';
      statusIcon = Icons.check_circle;
    } else {
      chipColor = AppColors.primaryColor;
      statusText = 'Active';
      statusIcon = Icons.poll;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollOptions() {
    return Column(
      children: widget.poll.options.map((option) {
        final voteCount = widget.poll.getOptionVoteCount(option.id);
        final percentage = widget.poll.totalVotes > 0
            ? (voteCount / widget.poll.totalVotes * 100)
            : 0.0;
        final isSelected = _selectedOptions.contains(option.id);

        return GestureDetector(
          onTap: () => _handleOptionTap(option.id),
          onHorizontalDragEnd: (details) =>
              _handleSwipeVote(option.id, details),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Stack(
              children: [
                // Progress background
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Progress bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width:
                            MediaQuery.of(context).size.width *
                            0.8 *
                            (percentage / 100),
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
                // Option content
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(
                          widget.poll.allowMultipleChoice
                              ? Icons.check_box
                              : Icons.radio_button_checked,
                          color: AppColors.primaryColor,
                          size: 20,
                        )
                      else
                        Icon(
                          widget.poll.allowMultipleChoice
                              ? Icons.check_box_outline_blank
                              : Icons.radio_button_unchecked,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '$voteCount vote${voteCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPollFooter() {
    return Row(
      children: [
        Icon(Icons.how_to_vote, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '${widget.poll.totalVotes} total vote${widget.poll.totalVotes == 1 ? '' : 's'}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          _getTimeRemaining(),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (widget.poll.allowCustomOptions && !widget.poll.isExpired)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showCustomOptionInput = !_showCustomOptionInput;
              });
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Option'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomOptionInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _customOptionController,
            decoration: InputDecoration(
              hintText: 'Enter custom option...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
            onSubmitted: _addCustomOption,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _addCustomOption,
          icon: const Icon(Icons.send),
          color: AppColors.primaryColor,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedResults() {
    // Find the winning option(s)
    final winningOptions = _getWinningOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, size: 16, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            Text(
              winningOptions.length > 1 ? 'Winners:' : 'Winner:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...winningOptions.map((option) {
          final voteCount = widget.poll.getOptionVoteCount(option.id);
          final percentage = widget.poll.totalVotes > 0
              ? (voteCount / widget.poll.totalVotes * 100)
              : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.text,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$voteCount vote${voteCount == 1 ? '' : 's'} (${percentage.toStringAsFixed(0)}%)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExpandHint() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.textHint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.expand_more, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(
              'Tap to expand',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PollOptionEntity> _getWinningOptions() {
    if (widget.poll.options.isEmpty) return [];

    // Find the maximum vote count
    int maxVotes = 0;
    for (final option in widget.poll.options) {
      final voteCount = widget.poll.getOptionVoteCount(option.id);
      if (voteCount > maxVotes) {
        maxVotes = voteCount;
      }
    }

    // Return all options with the maximum vote count
    return widget.poll.options
        .where(
          (option) => widget.poll.getOptionVoteCount(option.id) == maxVotes,
        )
        .toList();
  }

  void _handleOptionTap(String optionId) {
    if (widget.poll.isExpired) return;

    HapticFeedback.lightImpact();
    setState(() {
      if (widget.poll.allowMultipleChoice) {
        if (_selectedOptions.contains(optionId)) {
          _selectedOptions.remove(optionId);
        } else {
          _selectedOptions.add(optionId);
        }
      } else {
        _selectedOptions = {optionId};
      }
    });

    widget.onVote(widget.poll.id, _selectedOptions.toList());
    _triggerPulse();
  }

  void _handleSwipeVote(String optionId, DragEndDetails details) {
    if (widget.poll.isExpired) return;

    // Swipe right to vote
    if (details.primaryVelocity! > 0) {
      _handleOptionTap(optionId);
    }
  }

  void _addCustomOption([String? value]) {
    final optionText = value ?? _customOptionController.text.trim();
    if (optionText.isEmpty) return;

    widget.onAddCustomOption(widget.poll.id, optionText);
    _customOptionController.clear();
    setState(() {
      _showCustomOptionInput = false;
    });
  }

  String _getTimeRemaining() {
    if (widget.poll.isExpired) {
      return 'Expired';
    }

    final now = DateTime.now();
    final difference = widget.poll.expiresAt.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m left';
    } else {
      return 'Ending soon';
    }
  }

  void _showPollOptions() {
    final isCreator = widget.poll.creatorId == widget.currentUserId;
    if (!isCreator) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Poll Options', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (!widget.poll.isExpired) ...[
              ListTile(
                leading: const Icon(Icons.close, color: AppColors.warningColor),
                title: const Text('Close Poll'),
                subtitle: const Text('Stop accepting votes'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onClosePoll(widget.poll.id);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.errorColor),
              title: const Text('Delete Poll'),
              subtitle: const Text('Permanently remove this poll'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePoll();
              },
            ),
            if (widget.poll.hasUserVoted(widget.currentUserId)) ...[
              ListTile(
                leading: const Icon(
                  Icons.remove_circle,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Remove My Vote'),
                subtitle: const Text('Clear your current vote'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onRemoveVote(widget.poll.id);
                  setState(() {
                    _selectedOptions.clear();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDeletePoll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Poll'),
        content: const Text(
          'Are you sure you want to delete this poll? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeletePoll(widget.poll.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
