import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';
import 'package:critchat/features/gamification/domain/usecases/get_user_xp_usecase.dart';
import 'package:critchat/features/gamification/domain/usecases/award_xp_usecase.dart';
import 'package:critchat/features/gamification/domain/usecases/get_user_xp_stream_usecase.dart';
import 'package:critchat/features/gamification/domain/usecases/initialize_user_xp_usecase.dart';
import 'package:critchat/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:critchat/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:critchat/features/gamification/presentation/bloc/gamification_state.dart';

/// BLoC for managing gamification state
class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final GetUserXpUseCase _getUserXpUseCase;
  final AwardXpUseCase _awardXpUseCase;
  final GetUserXpStreamUseCase _getUserXpStreamUseCase;
  final InitializeUserXpUseCase _initializeUserXpUseCase;
  final GamificationRepository _repository;

  StreamSubscription<XpEntity>? _xpStreamSubscription;
  XpEntity? _previousXpState;

  GamificationBloc({
    required GetUserXpUseCase getUserXpUseCase,
    required AwardXpUseCase awardXpUseCase,
    required GetUserXpStreamUseCase getUserXpStreamUseCase,
    required InitializeUserXpUseCase initializeUserXpUseCase,
    required GamificationRepository repository,
  }) : _getUserXpUseCase = getUserXpUseCase,
       _awardXpUseCase = awardXpUseCase,
       _getUserXpStreamUseCase = getUserXpStreamUseCase,
       _initializeUserXpUseCase = initializeUserXpUseCase,
       _repository = repository,
       super(GamificationInitial()) {
    on<GetUserXp>(_onGetUserXp);
    on<AwardXp>(_onAwardXp);
    on<GetXpHistory>(_onGetXpHistory);
    on<StartXpStream>(_onStartXpStream);
    on<StopXpStream>(_onStopXpStream);
    on<XpUpdated>(_onXpUpdated);
    on<GetLeaderboard>(_onGetLeaderboard);
    on<InitializeUserXp>(_onInitializeUserXp);
    on<BatchAwardXp>(_onBatchAwardXp);
  }

  Future<void> _onGetUserXp(
    GetUserXp event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      emit(GamificationLoading());
      final xpEntity = await _getUserXpUseCase(event.userId);
      emit(UserXpLoaded(xpEntity: xpEntity));
    } catch (e) {
      debugPrint('Error getting user XP: $e');
      emit(
        GamificationError(message: 'Failed to load user XP: ${e.toString()}'),
      );
    }
  }

  Future<void> _onAwardXp(
    AwardXp event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      // Store previous state to check for level up
      final previousXp = await _getUserXpUseCase(event.userId);
      _previousXpState = previousXp;

      final newXpEntity = await _awardXpUseCase(
        event.userId,
        event.rewardType,
        metadata: event.metadata,
      );
      final leveledUp = newXpEntity.didLevelUp(previousXp);

      emit(
        XpAwarded(
          xpEntity: newXpEntity,
          rewardType: event.rewardType,
          leveledUp: leveledUp,
        ),
      );

      // Update streaming state if active
      if (_xpStreamSubscription != null) {
        emit(XpStreaming(xpEntity: newXpEntity));
      }
    } catch (e) {
      debugPrint('Error awarding XP: $e');
      emit(GamificationError(message: 'Failed to award XP: ${e.toString()}'));
    }
  }

  Future<void> _onGetXpHistory(
    GetXpHistory event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      emit(GamificationLoading());
      final transactions = await _repository.getUserXpHistory(
        event.userId,
        limit: event.limit,
      );
      emit(XpHistoryLoaded(transactions: transactions));
    } catch (e) {
      debugPrint('Error getting XP history: $e');
      emit(
        GamificationError(
          message: 'Failed to load XP history: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onStartXpStream(
    StartXpStream event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      await _xpStreamSubscription?.cancel();

      _xpStreamSubscription = _getUserXpStreamUseCase(event.userId).listen(
        (xpEntity) {
          add(XpUpdated(xpEntity: xpEntity));
        },
        onError: (error) {
          debugPrint('XP stream error: $error');
          add(
            XpUpdated(
              xpEntity: XpEntity(
                userId: '',
                totalXp: 0,
                currentLevel: 1,
                xpForCurrentLevel: 0,
                xpForNextLevel: 100,
                lastUpdated: DateTime.now(),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error starting XP stream: $e');
      emit(
        GamificationError(
          message: 'Failed to start XP stream: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onStopXpStream(
    StopXpStream event,
    Emitter<GamificationState> emit,
  ) async {
    await _xpStreamSubscription?.cancel();
    _xpStreamSubscription = null;
  }

  Future<void> _onXpUpdated(
    XpUpdated event,
    Emitter<GamificationState> emit,
  ) async {
    emit(XpStreaming(xpEntity: event.xpEntity));
  }

  Future<void> _onGetLeaderboard(
    GetLeaderboard event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      emit(GamificationLoading());
      final leaderboard = await _repository.getLeaderboard(limit: event.limit);
      emit(LeaderboardLoaded(leaderboard: leaderboard));
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      emit(
        GamificationError(
          message: 'Failed to load leaderboard: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onInitializeUserXp(
    InitializeUserXp event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      final xpEntity = await _initializeUserXpUseCase(event.userId);
      emit(UserXpInitialized(xpEntity: xpEntity));
    } catch (e) {
      debugPrint('Error initializing user XP: $e');
      emit(
        GamificationError(
          message: 'Failed to initialize user XP: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onBatchAwardXp(
    BatchAwardXp event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      // Store previous state to check for level up
      final previousXp = await _getUserXpUseCase(event.userId);
      _previousXpState = previousXp;

      final newXpEntity = await _repository.batchAwardXp(
        event.userId,
        event.rewardTypes,
        metadata: event.metadata,
      );
      final leveledUp = newXpEntity.didLevelUp(previousXp);

      emit(
        BatchXpAwarded(
          xpEntity: newXpEntity,
          rewardTypes: event.rewardTypes,
          leveledUp: leveledUp,
        ),
      );

      // Update streaming state if active
      if (_xpStreamSubscription != null) {
        emit(XpStreaming(xpEntity: newXpEntity));
      }
    } catch (e) {
      debugPrint('Error batch awarding XP: $e');
      emit(
        GamificationError(message: 'Failed to batch award XP: ${e.toString()}'),
      );
    }
  }

  @override
  Future<void> close() {
    _xpStreamSubscription?.cancel();
    return super.close();
  }
}
