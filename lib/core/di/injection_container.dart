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

// Core - Chat
import '../chat/chat_realtime_datasource.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseDatabase.instance);

  // Auth Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), firestore: sl()),
  );

  sl.registerLazySingleton<AuthFirestoreDataSource>(
    () => AuthFirestoreDataSourceImpl(firestore: sl(), auth: sl()),
  );

  // Friends Data sources
  sl.registerLazySingleton<FriendsFirestoreDataSource>(
    () => FriendsFirestoreDataSourceImpl(firestore: sl(), auth: sl()),
  );

  // Fellowship Data sources
  sl.registerLazySingleton<FellowshipFirestoreDataSource>(
    () => FellowshipFirestoreDataSourceImpl(firestore: sl()),
  );

  // Chat Data sources
  sl.registerLazySingleton<ChatRealtimeDataSource>(
    () => ChatRealtimeDataSourceImpl(database: sl(), auth: sl()),
  );

  // Auth Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Friends Repositories
  sl.registerLazySingleton<FriendsRepository>(
    () => FriendsRepositoryImpl(sl()),
  );

  // Fellowship Repositories
  sl.registerLazySingleton<FellowshipRepository>(
    () => FellowshipRepositoryImpl(
      fellowshipDataSource: sl(),
      authDataSource: sl(),
    ),
  );

  // Auth Use cases
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));

  // Friends Use cases
  sl.registerLazySingleton(() => GetFriendsUseCase(sl()));

  // Fellowship Use cases
  sl.registerLazySingleton(() => GetFellowshipsUseCase(repository: sl()));
  sl.registerLazySingleton(() => CreateFellowshipUseCase(repository: sl()));
  sl.registerLazySingleton(() => InviteFriendUseCase(repository: sl()));

  // Auth BLoC
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      signIn: sl(),
      signUp: sl(),
      signOut: sl(),
      authRepository: sl(),
    ),
  );

  // Friends BLoC
  sl.registerFactory(() => FriendsBloc(getFriendsUseCase: sl()));

  // Fellowship BLoC
  sl.registerFactory(
    () => FellowshipBloc(
      getFellowshipsUseCase: sl(),
      createFellowshipUseCase: sl(),
      inviteFriendUseCase: sl(),
    ),
  );
}
