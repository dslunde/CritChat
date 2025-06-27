import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/core/constants/app_colors.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/features/friends/domain/entities/friend_entity.dart';
import 'package:critchat/features/friends/domain/repositories/friends_repository.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_bloc.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_event.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_state.dart';

class SearchFriendsPage extends StatefulWidget {
  const SearchFriendsPage({super.key});

  @override
  State<SearchFriendsPage> createState() => _SearchFriendsPageState();
}

class _SearchFriendsPageState extends State<SearchFriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<FriendEntity> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // Use the friends repository search method
      final friendsRepo = sl<FriendsRepository>();
      final results = await friendsRepo.searchFriends(query.trim());

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendFriendRequest(FriendEntity user) {
    context.read<FriendsBloc>().add(AddFriend(user.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FriendsBloc>(),
      child: BlocListener<FriendsBloc, FriendsState>(
        listener: (context, state) {
          if (state is FriendRequestSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Friend request sent!'),
                backgroundColor: AppColors.successColor,
              ),
            );
          } else if (state is FriendsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Find Friends'),
            elevation: 0,
          ),
          body: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceColor,
                  border: Border(
                    bottom: BorderSide(color: AppColors.dividerColor),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search for friends by name...',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primaryColor,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.dividerColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundColor,
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  onChanged: (value) {
                    setState(() {}); // Refresh to show/hide clear button
                    if (value.trim().isNotEmpty) {
                      // Debounce search
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchController.text.trim() == value.trim()) {
                          _performSearch(value);
                        }
                      });
                    } else {
                      _performSearch('');
                    }
                  },
                  onSubmitted: _performSearch,
                  textInputAction: TextInputAction.search,
                ),
              ),

              // Results
              Expanded(child: _buildSearchResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryColor),
            SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for Friends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a name to find other CritChat users',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Users Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No users found matching "${_searchController.text.trim()}"',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Try searching with a different name',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppColors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: user.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person,
                                  color: AppColors.primaryColor,
                                  size: 24,
                                ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.bio!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (user.experienceLevel != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.experienceLevel!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Add Friend Button
                ElevatedButton.icon(
                  onPressed: () => _sendFriendRequest(user),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
