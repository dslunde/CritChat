import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Auth
import 'package:critchat/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:critchat/features/auth/data/datasources/auth_firestore_datasource.dart';
import 'package:critchat/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:critchat/features/auth/domain/repositories/auth_repository.dart';
import 'package:critchat/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/complete_onboarding_usecase.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';

// Friends
import 'package:critchat/features/friends/data/datasources/friends_firestore_datasource.dart';
import 'package:critchat/features/friends/data/repositories/friends_repository_impl.dart';
import 'package:critchat/features/friends/domain/repositories/friends_repository.dart';
import 'package:critchat/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:critchat/features/friends/domain/usecases/add_friend_usecase.dart';
import 'package:critchat/features/friends/domain/usecases/remove_friend_usecase.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_bloc.dart';

// Fellowships
import 'package:critchat/features/fellowships/data/datasources/fellowship_firestore_datasource.dart';
import 'package:critchat/features/fellowships/data/repositories/fellowship_repository_impl.dart';
import 'package:critchat/features/fellowships/domain/repositories/fellowship_repository.dart';
import 'package:critchat/features/fellowships/domain/usecases/get_fellowships_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/create_fellowship_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/invite_friend_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/get_public_fellowships_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/join_fellowship_by_code_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/remove_member_usecase.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_bloc.dart';

// Notifications
import 'package:critchat/features/notifications/data/datasources/notifications_firestore_datasource.dart';
import 'package:critchat/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:critchat/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:critchat/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:critchat/core/services/notification_indicator_service.dart';

// Chat
import 'package:critchat/core/chat/chat_realtime_datasource.dart';

// Polls
import 'package:critchat/features/polls/data/datasources/poll_realtime_datasource.dart';
import 'package:critchat/features/polls/data/repositories/poll_repository_impl.dart';
import 'package:critchat/features/polls/domain/repositories/poll_repository.dart';
import 'package:critchat/features/polls/domain/usecases/create_poll_usecase.dart';
import 'package:critchat/features/polls/domain/usecases/vote_on_poll_usecase.dart';
import 'package:critchat/features/polls/domain/usecases/get_fellowship_polls_usecase.dart';
import 'package:critchat/features/polls/domain/usecases/add_custom_option_usecase.dart';
import 'package:critchat/features/polls/presentation/bloc/poll_bloc.dart';

// Gamification
import 'package:critchat/features/gamification/data/datasources/gamification_firestore_datasource.dart';
import 'package:critchat/features/gamification/data/repositories/gamification_repository_impl.dart';
import 'package:critchat/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:critchat/features/gamification/domain/usecases/get_user_xp_usecase.dart';
import 'package:critchat/features/gamification/domain/usecases/award_xp_usecase.dart';
import 'package:critchat/features/gamification/domain/usecases/get_user_xp_stream_usecase.dart';
import 'package:critchat/features/gamification/domain/usecases/initialize_user_xp_usecase.dart';
import 'package:critchat/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:critchat/core/gamification/gamification_service.dart';

// LFG
import 'package:critchat/features/lfg/data/datasources/lfg_firestore_datasource.dart';
import 'package:critchat/features/lfg/data/datasources/lfg_rag_datasource.dart';
import 'package:critchat/features/lfg/data/repositories/lfg_repository_impl.dart';
import 'package:critchat/features/lfg/domain/repositories/lfg_repository.dart';
import 'package:critchat/features/lfg/domain/usecases/create_lfg_post_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/get_active_lfg_posts_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/get_user_lfg_posts_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/express_interest_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/close_lfg_post_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/refresh_lfg_post_usecase.dart';
import 'package:critchat/features/lfg/domain/usecases/create_fellowship_from_post_usecase.dart';
import 'package:critchat/features/lfg/data/services/lfg_matching_service.dart';
import 'package:critchat/features/lfg/presentation/bloc/lfg_bloc.dart';

// Characters
import 'package:critchat/features/characters/data/datasources/character_firestore_datasource.dart';
import 'package:critchat/features/characters/data/repositories/character_repository_impl.dart';
import 'package:critchat/features/characters/domain/repositories/character_repository.dart';
import 'package:critchat/features/characters/domain/usecases/create_character_usecase.dart';
import 'package:critchat/features/characters/domain/usecases/get_user_character_usecase.dart';
import 'package:critchat/features/characters/domain/usecases/update_character_usecase.dart';
import 'package:critchat/features/characters/presentation/bloc/character_bloc.dart';

// RAG & Vector Database
import 'package:critchat/core/rag/rag_service.dart';
import 'package:critchat/core/config/rag_config.dart';
import 'package:critchat/core/config/app_config.dart';
import 'package:critchat/core/embeddings/embedding_service.dart';
import 'package:critchat/core/vector_db/weaviate_service.dart';
import 'package:critchat/core/llm/llm_service.dart';
import 'package:critchat/features/characters/domain/repositories/character_memory_repository.dart';
import 'package:critchat/features/characters/domain/usecases/store_character_memory_usecase.dart';
import 'package:critchat/features/characters/domain/usecases/search_character_memories_usecase.dart';
import 'package:critchat/features/characters/data/datasources/character_memory_weaviate_datasource.dart';
import 'package:critchat/features/characters/data/datasources/character_memory_mock_datasource.dart';
import 'package:critchat/features/characters/data/repositories/character_memory_repository_impl.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  _initExternalDependencies();

  // Core infrastructure (must come first)
  _initRagConfig();
  _initRagInfrastructure();
  
  // Feature modules
  _initAuth();
  _initFriends();
  _initFellowships();
  _initNotifications();
  _initCharacters();
  _initCharacterMemory();
  _initRag();
  _initChat();
  _initPolls();
  _initGamification();
  _initLfg();

  // Initialize Weaviate schema if available
  await _initializeWeaviateSchema();

  // Initialize fellowship memberships for Realtime Database security rules
  await _initializeFellowshipMemberships();
}

Future<void> _initializeWeaviateSchema() async {
  try {
    final weaviateService = sl.isRegistered<WeaviateService>() ? sl<WeaviateService>() : null;
    if (weaviateService != null) {
      debugPrint('🔧 Initializing Weaviate schema...');
      await weaviateService.initializeSchema();
      debugPrint('✅ Weaviate schema initialized successfully');
    }
  } catch (e) {
    // Log error but don't crash the app
    debugPrint('⚠️ Failed to initialize Weaviate schema: $e');
    debugPrint('   Vector database features may not work properly');
  }
}

Future<void> _initializeFellowshipMemberships() async {
  try {
    final fellowshipDataSource = sl<FellowshipFirestoreDataSource>();
    await fellowshipDataSource.syncFellowshipMemberships();
  } catch (e) {
    // Log error but don't crash the app
    debugPrint('Failed to sync fellowship memberships: $e');
  }
}

void _initExternalDependencies() {
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseDatabase.instance);
}

void _initAuth() {
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), firestore: sl()),
  );

  sl.registerLazySingleton<AuthFirestoreDataSource>(
    () => AuthFirestoreDataSourceImpl(firestore: sl(), auth: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetAuthStateChangesUseCase(sl()));
  sl.registerLazySingleton(() => CompleteOnboardingUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      signIn: sl(),
      signUp: sl(),
      signOut: sl(),
      getAuthStateChanges: sl(),
      completeOnboarding: sl(),
      gamificationService: sl(),
    ),
  );
}

void _initFriends() {
  // Data sources
  sl.registerLazySingleton<FriendsFirestoreDataSource>(
    () => FriendsFirestoreDataSourceImpl(
      firestore: sl(),
      auth: sl(),
      database: sl(),
      notificationsRepository: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<FriendsRepository>(
    () => FriendsRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetFriendsUseCase(sl()));
  sl.registerLazySingleton(() => AddFriendUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFriendUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => FriendsBloc(
      getFriendsUseCase: sl(),
      addFriendUseCase: sl(),
      removeFriendUseCase: sl(),
    ),
  );
}

void _initFellowships() {
  // Data sources
  sl.registerLazySingleton<FellowshipFirestoreDataSource>(
    () => FellowshipFirestoreDataSourceImpl(firestore: sl(), database: sl()),
  );

  // Repositories
  sl.registerLazySingleton<FellowshipRepository>(
    () => FellowshipRepositoryImpl(
      fellowshipDataSource: sl(),
      authDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetFellowshipsUseCase(repository: sl()));
  sl.registerLazySingleton(() => CreateFellowshipUseCase(repository: sl()));
  sl.registerLazySingleton(() => InviteFriendUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetPublicFellowshipsUseCase(repository: sl()));
  sl.registerLazySingleton(() => JoinFellowshipByCodeUseCase(repository: sl()));
  sl.registerLazySingleton(() => RemoveMemberUseCase(repository: sl()));

  // BLoC
  sl.registerFactory(
    () => FellowshipBloc(
      getFellowshipsUseCase: sl(),
      createFellowshipUseCase: sl(),
      inviteFriendUseCase: sl(),
      getPublicFellowshipsUseCase: sl(),
      joinFellowshipByCodeUseCase: sl(),
      removeMemberUseCase: sl(),
    ),
  );
}

void _initNotifications() {
  // Data sources
  sl.registerLazySingleton<NotificationsDataSource>(
    () => NotificationsRealtimeDataSourceImpl(
      database: sl(),
      auth: sl(),
      firestore: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(sl()),
  );

  // Services
  sl.registerLazySingleton(
    () => NotificationIndicatorService(notificationsRepository: sl()),
  );

  // BLoC
  sl.registerFactory(
    () => NotificationsBloc(repository: sl(), indicatorService: sl()),
  );
}

void _initCharacters() {
  // Data sources
  sl.registerLazySingleton<CharacterFirestoreDataSource>(
    () => CharacterFirestoreDataSourceImpl(firestore: sl()),
  );

  // Repositories
  sl.registerLazySingleton<CharacterRepository>(
    () => CharacterRepositoryImpl(dataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateCharacterUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetUserCharacterUseCase(repository: sl()));
  sl.registerLazySingleton(() => UpdateCharacterUseCase(repository: sl()));

  // BLoC
  sl.registerFactory(
    () => CharacterBloc(
      createCharacterUseCase: sl(),
      getUserCharacterUseCase: sl(),
      updateCharacterUseCase: sl(),
      ragService: sl(),
    ),
  );
}

void _initRagConfig() {
  // RAG Configuration - now uses centralized AppConfig
  sl.registerLazySingleton<RagConfig>(
    () {
      AppConfig.logConfiguration();
      final config = AppConfig.getRagConfig();
      config.logConfiguration();
      return config;
    },
  );
}

void _initRagInfrastructure() {
  final config = sl<RagConfig>();

  // Embedding Service
  sl.registerLazySingleton<EmbeddingService>(() {
    if (config.useMockServices || !config.hasOpenAiKey) {
      debugPrint('🔧 Using mock embedding service');
      return MockEmbeddingService();
    } else {
      debugPrint('🔧 Using OpenAI embedding service');
      return OpenAIEmbeddingService(apiKey: config.openAiApiKey);
    }
  });

  // LLM Service
  sl.registerLazySingleton<LlmService>(() {
    if (config.useMockServices || !config.hasOpenAiKey) {
      debugPrint('🔧 Using mock LLM service');
      return MockLlmService();
    } else {
      debugPrint('🔧 Using OpenAI LLM service');
      return OpenAILlmService(apiKey: config.openAiApiKey);
    }
  });

  // Weaviate Service (if configured or using mocks)
  if (config.hasWeaviateConfig || config.useMockServices) {
    sl.registerLazySingleton<WeaviateService>(() {
      if (config.useMockServices || !config.hasWeaviateConfig) {
        debugPrint('🔧 Using mock Weaviate service');
        // For mock mode, use a simple configuration
        return WeaviateService(
          config: const WeaviateConfig(url: 'mock://localhost:8080'),
        );
      } else {
        debugPrint('🔧 Using real Weaviate vector database');
        return WeaviateService(config: config.weaviateConfig!);
      }
    });
  }
}

void _initCharacterMemory() {
  final config = sl<RagConfig>();

  // Character Memory Data Source (only if we have Weaviate or using mocks)
  if (config.hasWeaviateConfig || config.useMockServices) {
    sl.registerLazySingleton<CharacterMemoryWeaviateDataSource>(() {
      if (config.useMockServices || !config.hasWeaviateConfig) {
        debugPrint('🔧 Using mock character memory data source');
        return CharacterMemoryMockDataSourceImpl();
      } else {
        debugPrint('🔧 Using Weaviate character memory data source');
        return CharacterMemoryWeaviateDataSourceImpl(
          weaviateService: sl<WeaviateService>(),
          embeddingService: sl<EmbeddingService>(),
        );
      }
    });

    // Character Memory Repository
    sl.registerLazySingleton<CharacterMemoryRepository>(
      () => CharacterMemoryRepositoryImpl(dataSource: sl()),
    );

    // Character Memory Use Cases
    sl.registerLazySingleton(() => StoreCharacterMemoryUseCase(
      repository: sl(),
      embeddingService: sl(),
    ));
    
    sl.registerLazySingleton(() => SearchCharacterMemoriesUseCase(
      repository: sl(),
    ));
  }
}

void _initRag() {
  final config = sl<RagConfig>();

  // RAG Service
  sl.registerLazySingleton<RagService>(() {
    if (!config.enableRag) {
      debugPrint('🔧 RAG disabled, using simple responses only');
      return RagServiceImpl();
    }

    CharacterMemoryRepository? memoryRepository;
    LlmService? llmService;

    // Try to get optional dependencies
    try {
      memoryRepository = sl<CharacterMemoryRepository>();
    } catch (e) {
      debugPrint('⚠️ Character memory repository not available');
    }

    try {
      llmService = sl<LlmService>();
    } catch (e) {
      debugPrint('⚠️ LLM service not available');
    }

    if (memoryRepository != null && llmService != null) {
      debugPrint('🔧 Using enhanced RAG service with vector database and LLM');
    } else {
      debugPrint('🔧 Using basic RAG service (some components unavailable)');
    }

    return RagServiceImpl(
      memoryRepository: memoryRepository,
      llmService: llmService,
    );
  });
}

void _initChat() {
  // Data sources
  sl.registerLazySingleton<ChatRealtimeDataSource>(
    () => ChatRealtimeDataSourceImpl(
      database: sl(),
      auth: sl(),
      firestore: sl(),
      notificationsRepository: sl(),
      characterRepository: sl(),
      ragService: sl(),
    ),
  );
}

void _initPolls() {
  // Data sources
  sl.registerLazySingleton<PollRealtimeDataSource>(
    () => PollRealtimeDataSourceImpl(
      database: sl(),
      auth: sl(),
      firestore: sl(),
      notificationsRepository: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<PollRepository>(
    () => PollRepositoryImpl(dataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => CreatePollUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => VoteOnPollUseCase(repository: sl(), auth: sl()),
  );
  sl.registerLazySingleton(() => GetFellowshipPollsUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => AddCustomOptionUseCase(repository: sl(), auth: sl()),
  );

  // BLoC
  sl.registerFactory(
    () => PollBloc(
      createPollUseCase: sl(),
      voteOnPollUseCase: sl(),
      getFellowshipPollsUseCase: sl(),
      addCustomOptionUseCase: sl(),
      pollRepository: sl(),
    ),
  );
}

void _initGamification() {
  // Data sources
  sl.registerLazySingleton<GamificationFirestoreDataSource>(
    () => GamificationFirestoreDataSourceImpl(firestore: sl(), auth: sl()),
  );

  // Repositories
  sl.registerLazySingleton<GamificationRepository>(
    () => GamificationRepositoryImpl(dataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetUserXpUseCase(repository: sl()));
  sl.registerLazySingleton(() => AwardXpUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetUserXpStreamUseCase(repository: sl()));
  sl.registerLazySingleton(() => InitializeUserXpUseCase(repository: sl()));

  // BLoC
  sl.registerFactory(
    () => GamificationBloc(
      getUserXpUseCase: sl(),
      awardXpUseCase: sl(),
      getUserXpStreamUseCase: sl(),
      initializeUserXpUseCase: sl(),
      repository: sl(),
    ),
  );

  // Service
  sl.registerLazySingleton(() => GamificationService()..initialize());
}

void _initLfg() {
  // Data sources
  sl.registerLazySingleton<LfgFirestoreDataSource>(
    () => LfgFirestoreDataSourceImpl(
      firestore: sl(),
    ),
  );

  // RAG data source (optional - fallback to mock if Weaviate unavailable)
  final ragConfig = sl<RagConfig>();
  if (ragConfig.enableRag && ragConfig.hasWeaviateConfig) {
    sl.registerLazySingleton<LfgRagDataSource>(
      () => LfgRagDataSourceImpl(
        weaviateService: sl(),
        embeddingService: sl(),
      ),
    );
  } else {
    sl.registerLazySingleton<LfgRagDataSource>(
      () => LfgRagMockDataSource(),
    );
  }

  // Services
  sl.registerLazySingleton(
    () => LfgMatchingService(ragDataSource: sl()),
  );

  // Repositories
  sl.registerLazySingleton<LfgRepository>(
    () => LfgRepositoryImpl(
      ragConfig: ragConfig,
      firestoreDataSource: sl(),
      ragDataSource: sl(),
      matchingService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateLfgPostUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetActiveLfgPostsUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetUserLfgPostsUseCase(repository: sl()));
  sl.registerLazySingleton(() => ExpressInterestUseCase(repository: sl()));
  sl.registerLazySingleton(() => CloseLfgPostUseCase(repository: sl()));
  sl.registerLazySingleton(() => RefreshLfgPostUseCase(repository: sl()));
  sl.registerLazySingleton(() => CreateFellowshipFromPostUseCase(
    lfgRepository: sl(),
    fellowshipRepository: sl(),
  ));

  // BLoC
  sl.registerFactory(
    () => LfgBloc(
      createLfgPostUseCase: sl(),
      getActiveLfgPostsUseCase: sl(),
      getUserLfgPostsUseCase: sl(),
      expressInterestUseCase: sl(),
      closeLfgPostUseCase: sl(),
      refreshLfgPostUseCase: sl(),
      createFellowshipFromPostUseCase: sl(),
    ),
  );
}
