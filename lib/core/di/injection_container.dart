import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

// Features - Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_firestore_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/auth/domain/usecases/get_auth_state_changes_usecase.dart';
import '../../features/auth/domain/usecases/complete_onboarding_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Features - Friends
import '../../features/friends/data/datasources/friends_firestore_datasource.dart';
import '../../features/friends/data/repositories/friends_repository_impl.dart';
import '../../features/friends/domain/repositories/friends_repository.dart';
import '../../features/friends/domain/usecases/get_friends_usecase.dart';
import '../../features/friends/presentation/bloc/friends_bloc.dart';

// Features - Fellowships
import '../../features/fellowships/data/datasources/fellowship_firestore_datasource.dart';
import '../../features/fellowships/data/repositories/fellowship_repository_impl.dart';
import '../../features/fellowships/domain/repositories/fellowship_repository.dart';
import '../../features/fellowships/domain/usecases/get_fellowships_usecase.dart';
import '../../features/fellowships/domain/usecases/create_fellowship_usecase.dart';
import '../../features/fellowships/domain/usecases/invite_friend_usecase.dart';
import '../../features/fellowships/presentation/bloc/fellowship_bloc.dart';

// Features - Notifications
import '../../features/notifications/data/datasources/notifications_firestore_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';

// Core - Chat
import '../chat/chat_realtime_datasource.dart';

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
    () => FellowshipFirestoreDataSourceImpl(firestore: sl()),
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

  // BLoC
  sl.registerFactory(
    () => FellowshipBloc(
      getFellowshipsUseCase: sl(),
      createFellowshipUseCase: sl(),
      inviteFriendUseCase: sl(),
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
    () => ChatRealtimeDataSourceImpl(database: sl(), auth: sl()),
  );
}
