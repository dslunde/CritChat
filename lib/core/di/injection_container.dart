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

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  _initExternalDependencies();

  // Feature modules
  _initAuth();
  _initFriends();
  _initFellowships();
  _initNotifications();
  _initChat();
  _initPolls();
  _initGamification();

  // Initialize fellowship memberships for Realtime Database security rules
  await _initializeFellowshipMemberships();
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
    ),
  );
}

void _initFriends() {
  // Data sources
  sl.registerLazySingleton<FriendsFirestoreDataSource>(
    () => FriendsFirestoreDataSourceImpl(firestore: sl(), auth: sl()),
  );

  // Repositories
  sl.registerLazySingleton<FriendsRepository>(
    () => FriendsRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetFriendsUseCase(sl()));

  // BLoC
  sl.registerFactory(() => FriendsBloc(getFriendsUseCase: sl()));
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
  sl.registerLazySingleton<NotificationsFirestoreDataSource>(
    () => NotificationsFirestoreDataSourceImpl(firestore: sl(), auth: sl()),
  );

  // Repositories
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(sl()),
  );

  // BLoC
  sl.registerFactory(() => NotificationsBloc(repository: sl()));
}

void _initChat() {
  // Data sources
  sl.registerLazySingleton<ChatRealtimeDataSource>(
    () =>
        ChatRealtimeDataSourceImpl(database: sl(), auth: sl(), firestore: sl()),
  );
}

void _initPolls() {
  // Data sources
  sl.registerLazySingleton<PollRealtimeDataSource>(
    () =>
        PollRealtimeDataSourceImpl(database: sl(), auth: sl(), firestore: sl()),
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
