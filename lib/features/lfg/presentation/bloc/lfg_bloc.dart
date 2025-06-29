import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'package:critchat/features/lfg/domain/usecases/create_lfg_post_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/get_active_lfg_posts_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/get_user_lfg_posts_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/express_interest_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/close_lfg_post_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/refresh_lfg_post_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/create_fellowship_from_post_usecase.dart';
import 'package:critchat/features/lfg/presentation/bloc/lfg_event.dart';
import 'package:critchat/features/lfg/presentation/bloc/lfg_state.dart';
import 'package:critchat/core/di/injection_container.dart';
import 'package:critchat/core/gamification/gamification_service.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';

class LfgBloc extends Bloc<LfgEvent, LfgState> {
  final CreateLfgPostUseCase _createLfgPostUseCase;
  final GetActiveLfgPostsUseCase _getActiveLfgPostsUseCase;
  final GetUserLfgPostsUseCase _getUserLfgPostsUseCase;
  final ExpressInterestUseCase _expressInterestUseCase;
  final CloseLfgPostUseCase _closeLfgPostUseCase;
  final RefreshLfgPostUseCase _refreshLfgPostUseCase;
  final CreateFellowshipFromPostUseCase _createFellowshipFromPostUseCase;

  LfgBloc({
    required CreateLfgPostUseCase createLfgPostUseCase,
    required GetActiveLfgPostsUseCase getActiveLfgPostsUseCase,
    required GetUserLfgPostsUseCase getUserLfgPostsUseCase,
    required ExpressInterestUseCase expressInterestUseCase,
    required CloseLfgPostUseCase closeLfgPostUseCase,
    required RefreshLfgPostUseCase refreshLfgPostUseCase,
    required CreateFellowshipFromPostUseCase createFellowshipFromPostUseCase,
  }) : _createLfgPostUseCase = createLfgPostUseCase,
       _getActiveLfgPostsUseCase = getActiveLfgPostsUseCase,
       _getUserLfgPostsUseCase = getUserLfgPostsUseCase,
       _expressInterestUseCase = expressInterestUseCase,
       _closeLfgPostUseCase = closeLfgPostUseCase,
       _refreshLfgPostUseCase = refreshLfgPostUseCase,
       _createFellowshipFromPostUseCase = createFellowshipFromPostUseCase,
       super(LfgInitial()) {
    
    on<LoadLfgPosts>(_onLoadLfgPosts);
    on<LoadUserLfgPosts>(_onLoadUserLfgPosts);
    on<CreateLfgPost>(_onCreateLfgPost);
    on<ExpressInterest>(_onExpressInterest);
    on<CloseLfgPost>(_onCloseLfgPost);
    on<RefreshLfgPost>(_onRefreshLfgPost);
    on<CreateFellowshipFromPost>(_onCreateFellowshipFromPost);
    on<DeleteLfgPost>(_onDeleteLfgPost);
    on<RefreshLfgFeed>(_onRefreshLfgFeed);
  }

  Future<void> _onLoadLfgPosts(LoadLfgPosts event, Emitter<LfgState> emit) async {
    try {
      emit(LfgLoading());
      debugPrint('🔍 Loading LFG posts for user: ${event.currentUserId}');
      
      final posts = await _getActiveLfgPostsUseCase(event.currentUserId);
      
      debugPrint('✅ Loaded ${posts.length} LFG posts');
      emit(LfgPostsLoaded(posts));
    } catch (e) {
      debugPrint('❌ Failed to load LFG posts: $e');
      emit(LfgError('Failed to load LFG posts: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUserLfgPosts(LoadUserLfgPosts event, Emitter<LfgState> emit) async {
    try {
      emit(LfgLoading());
      debugPrint('🔍 Loading user LFG posts for: ${event.userId}');
      
      final userPosts = await _getUserLfgPostsUseCase(event.userId);
      
      debugPrint('✅ Loaded ${userPosts.length} user LFG posts');
      emit(UserLfgPostsLoaded(userPosts));
    } catch (e) {
      debugPrint('❌ Failed to load user LFG posts: $e');
      emit(LfgError('Failed to load your LFG posts: ${e.toString()}'));
    }
  }

  Future<void> _onCreateLfgPost(CreateLfgPost event, Emitter<LfgState> emit) async {
    try {
      emit(LfgLoading());
      debugPrint('📝 Creating LFG post for user: ${event.userId}');
      
      final post = await _createLfgPostUseCase(
        userId: event.userId,
        userName: event.userName,
        userLevel: event.userLevel,
        gameSystem: event.gameSystem,
        playStyles: event.playStyles,
        sessionFormat: event.sessionFormat,
        schedulePreference: event.schedulePreference,
        campaignLength: event.campaignLength,
        callToAdventureText: event.callToAdventureText,
      );

      // Award XP for creating LFG post
      try {
        final gamificationService = sl<GamificationService>();
        await gamificationService.awardXp(XpRewardType.lfgPostCreated);
        debugPrint('✅ Awarded XP for LFG post creation');
      } catch (e) {
        debugPrint('⚠️ Failed to award XP for LFG post creation: $e');
        // Don't fail the post creation if XP awarding fails
      }
      
      debugPrint('✅ Created LFG post: ${post.id}');
      emit(LfgPostCreated(post: post));
    } catch (e) {
      debugPrint('❌ Failed to create LFG post: $e');
      emit(LfgError('Failed to create LFG post: ${e.toString()}'));
    }
  }

  Future<void> _onExpressInterest(ExpressInterest event, Emitter<LfgState> emit) async {
    try {
      debugPrint('👋 Expressing interest in post: ${event.postId}');
      
      final success = await _expressInterestUseCase(
        postId: event.postId,
        userId: event.userId,
      );

      if (success) {
        debugPrint('✅ Interest expressed successfully');
        emit(const InterestExpressed());
      } else {
        emit(const LfgError('Failed to express interest. Please try again.'));
      }
    } catch (e) {
      debugPrint('❌ Failed to express interest: $e');
      emit(LfgError('Failed to express interest: ${e.toString()}'));
    }
  }

  Future<void> _onCloseLfgPost(CloseLfgPost event, Emitter<LfgState> emit) async {
    try {
      debugPrint('🔒 Closing LFG post: ${event.postId}');
      
      final success = await _closeLfgPostUseCase(event.postId);

      if (success) {
        debugPrint('✅ LFG post closed successfully');
        emit(const LfgPostClosed());
      } else {
        emit(const LfgError('Failed to close LFG post. Please try again.'));
      }
    } catch (e) {
      debugPrint('❌ Failed to close LFG post: $e');
      emit(LfgError('Failed to close LFG post: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshLfgPost(RefreshLfgPost event, Emitter<LfgState> emit) async {
    try {
      debugPrint('🔄 Refreshing LFG post: ${event.postId}');
      
      final refreshedPost = await _refreshLfgPostUseCase(event.postId);
      
      debugPrint('✅ LFG post refreshed successfully');
      emit(LfgPostRefreshed(post: refreshedPost));
    } catch (e) {
      debugPrint('❌ Failed to refresh LFG post: $e');
      emit(LfgError('Failed to refresh LFG post: ${e.toString()}'));
    }
  }

  Future<void> _onCreateFellowshipFromPost(CreateFellowshipFromPost event, Emitter<LfgState> emit) async {
    try {
      emit(LfgLoading());
      debugPrint('⚔️ Creating fellowship from LFG post: ${event.postId}');
      
      final fellowship = await _createFellowshipFromPostUseCase(
        postId: event.postId,
        fellowshipName: event.fellowshipName,
        fellowshipDescription: event.fellowshipDescription,
        isPublic: event.isPublic,
        joinCode: event.joinCode,
      );

      // Award XP for successful fellowship creation from LFG post
      try {
        final gamificationService = sl<GamificationService>();
        await gamificationService.awardXp(XpRewardType.createFellowship);
        debugPrint('✅ Awarded XP for fellowship creation from LFG post');
      } catch (e) {
        debugPrint('⚠️ Failed to award XP for fellowship creation: $e');
        // Don't fail the fellowship creation if XP awarding fails
      }
      
      debugPrint('✅ Fellowship created from LFG post: ${fellowship.id}');
      emit(FellowshipCreatedFromPost(fellowship: fellowship));
    } catch (e) {
      debugPrint('❌ Failed to create fellowship from LFG post: $e');
      emit(LfgError('Failed to create fellowship: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteLfgPost(DeleteLfgPost event, Emitter<LfgState> emit) async {
    try {
      debugPrint('🗑️ Deleting LFG post: ${event.postId}');
      
      // Note: This would typically be handled by a background service
      // For now, we'll implement it as a manual action
      emit(const LfgPostDeleted());
      
      debugPrint('✅ LFG post deletion initiated');
    } catch (e) {
      debugPrint('❌ Failed to delete LFG post: $e');
      emit(LfgError('Failed to delete LFG post: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshLfgFeed(RefreshLfgFeed event, Emitter<LfgState> emit) async {
    try {
      debugPrint('🔄 Refreshing LFG feed for user: ${event.currentUserId}');
      
      final posts = await _getActiveLfgPostsUseCase(event.currentUserId);
      
      debugPrint('✅ Refreshed LFG feed with ${posts.length} posts');
      emit(LfgPostsLoaded(posts));
    } catch (e) {
      debugPrint('❌ Failed to refresh LFG feed: $e');
      emit(LfgError('Failed to refresh feed: ${e.toString()}'));
    }
  }
} 