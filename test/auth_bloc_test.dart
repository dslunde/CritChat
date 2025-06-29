import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:critchat/features/auth/domain/entities/user_entity.dart';
import 'package:critchat/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:critchat/features/auth/domain/usecases/complete_onboarding_usecase.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_event.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';
import 'package:critchat/core/gamification/gamification_service.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';

// Mock classes
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockSignInUseCase extends Mock implements SignInUseCase {}

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockGetAuthStateChangesUseCase extends Mock
    implements GetAuthStateChangesUseCase {}

class MockCompleteOnboardingUseCase extends Mock
    implements CompleteOnboardingUseCase {}

class MockGamificationService extends Mock implements GamificationService {}

void main() {
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockSignInUseCase mockSignInUseCase;
  late MockSignUpUseCase mockSignUpUseCase;
  late MockSignOutUseCase mockSignOutUseCase;
  late MockGetAuthStateChangesUseCase mockGetAuthStateChangesUseCase;
  late MockCompleteOnboardingUseCase mockCompleteOnboardingUseCase;
  late MockGamificationService mockGamificationService;
  late StreamController<UserEntity?> authStateController;

  setUpAll(() {
    registerFallbackValue(XpRewardType.signUp);
  });

  const testUser = UserEntity(
    id: 'test-id',
    email: 'test@example.com',
    displayName: 'Test User',
    bio: 'Test bio',
    experienceLevel: 'Intermediate',
    preferredSystems: ['D&D 5e'],
    friends: [],
    fellowships: [],
  );

  const testUserNeedsOnboarding = UserEntity(
    id: 'test-id',
    email: 'test@example.com',
    displayName: null,
    bio: null,
    experienceLevel: null,
    preferredSystems: [],
    friends: [],
    fellowships: [],
  );

  AuthBloc createAuthBloc() {
    return AuthBloc(
      getCurrentUser: mockGetCurrentUserUseCase,
      signIn: mockSignInUseCase,
      signUp: mockSignUpUseCase,
      signOut: mockSignOutUseCase,
      getAuthStateChanges: mockGetAuthStateChangesUseCase,
      completeOnboarding: mockCompleteOnboardingUseCase,
      gamificationService: mockGamificationService,
    );
  }

  setUp(() {
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockSignInUseCase = MockSignInUseCase();
    mockSignUpUseCase = MockSignUpUseCase();
    mockSignOutUseCase = MockSignOutUseCase();
    mockGetAuthStateChangesUseCase = MockGetAuthStateChangesUseCase();
    mockCompleteOnboardingUseCase = MockCompleteOnboardingUseCase();
    mockGamificationService = MockGamificationService();
    authStateController = StreamController<UserEntity?>.broadcast();

    when(
      () => mockGetAuthStateChangesUseCase(),
    ).thenAnswer((_) => authStateController.stream);

    // Setup default mock behavior for gamification service
    when(
      () => mockGamificationService.initializeUserXp(any()),
    ).thenAnswer((_) async => null);
    when(() => mockGamificationService.awardXp(any())).thenAnswer((_) async => null);
  });

  tearDown(() {
    authStateController.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      final authBloc = createAuthBloc();
      expect(authBloc.state, equals(const AuthInitial()));
      authBloc.close();
    });

    group('AuthStarted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when user is found',
        build: () {
          when(
            () => mockGetCurrentUserUseCase(),
          ).thenAnswer((_) async => testUser);
          return createAuthBloc();
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(user: testUser, needsOnboarding: false),
        ],
        verify: (_) {
          verify(() => mockGetCurrentUserUseCase()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] with needsOnboarding=true when user needs onboarding',
        build: () {
          when(
            () => mockGetCurrentUserUseCase(),
          ).thenAnswer((_) async => testUserNeedsOnboarding);
          return createAuthBloc();
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(
            user: testUserNeedsOnboarding,
            needsOnboarding: true,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when no user is found',
        build: () {
          when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
          return createAuthBloc();
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [const AuthLoading(), const AuthUnauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when getCurrentUser throws',
        build: () {
          when(
            () => mockGetCurrentUserUseCase(),
          ).thenThrow(Exception('Test error'));
          return createAuthBloc();
        },
        act: (bloc) => bloc.add(const AuthStarted()),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Exception: Test error'),
        ],
      );
    });

    group('AuthStateChanged (Stream)', () {
      blocTest<AuthBloc, AuthState>(
        'emits AuthAuthenticated when stream emits user',
        build: () => createAuthBloc(),
        act: (bloc) => authStateController.add(testUser),
        expect: () => [
          const AuthAuthenticated(user: testUser, needsOnboarding: false),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits AuthAuthenticated with needsOnboarding=true when stream emits user needing onboarding',
        build: () => createAuthBloc(),
        act: (bloc) => authStateController.add(testUserNeedsOnboarding),
        expect: () => [
          const AuthAuthenticated(
            user: testUserNeedsOnboarding,
            needsOnboarding: true,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits AuthUnauthenticated when stream emits null',
        build: () => createAuthBloc(),
        act: (bloc) => authStateController.add(null),
        expect: () => [const AuthUnauthenticated()],
      );
    });

    group('AuthSignInRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading] and calls signIn use case successfully',
        build: () {
          when(
            () => mockSignInUseCase(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer((_) async => testUser);
          return createAuthBloc();
        },
        act: (bloc) => bloc.add(
          const AuthSignInRequested(
            email: 'test@example.com',
            password: 'password',
          ),
        ),
        expect: () => [const AuthLoading()],
        verify: (_) {
          verify(
            () => mockSignInUseCase(
              email: 'test@example.com',
              password: 'password',
            ),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when signIn throws',
        build: () {
          when(
            () => mockSignInUseCase(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(Exception('Sign in failed'));
          return createAuthBloc();
        },
        act: (bloc) => bloc.add(
          const AuthSignInRequested(
            email: 'test@example.com',
            password: 'password',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Exception: Sign in failed'),
        ],
      );
    });

    group('AuthSignUpRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading] and calls signUp use case successfully',
        build: () {
          when(
            () => mockSignUpUseCase(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer((_) async => testUser);
          return createAuthBloc();
        },
        act: (bloc) => bloc.add(
          const AuthSignUpRequested(
            email: 'test@example.com',
            password: 'password',
          ),
        ),
        expect: () => [const AuthLoading()],
        verify: (_) {
          verify(
            () => mockSignUpUseCase(
              email: 'test@example.com',
              password: 'password',
            ),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when signUp throws',
        build: () {
          when(
            () => mockSignUpUseCase(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(Exception('Sign up failed'));
          return createAuthBloc();
        },
        act: (bloc) => bloc.add(
          const AuthSignUpRequested(
            email: 'test@example.com',
            password: 'password',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Exception: Sign up failed'),
        ],
      );
    });

    group('AuthSignOutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthSigningOut] and calls signOut use case',
        build: () {
          when(() => mockSignOutUseCase()).thenAnswer((_) async {});
          return createAuthBloc();
        },
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [const AuthSigningOut()],
        verify: (_) {
          verify(() => mockSignOutUseCase()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthError] when signOut throws',
        build: () {
          when(
            () => mockSignOutUseCase(),
          ).thenThrow(Exception('Sign out failed'));
          return createAuthBloc();
        },
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [
          const AuthSigningOut(),
          const AuthError(message: 'Exception: Sign out failed'),
        ],
      );
    });

    group('AuthOnboardingCompleted', () {
      const updatedUser = UserEntity(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Updated User',
        bio: 'Updated bio',
        experienceLevel: 'Expert',
        preferredSystems: ['D&D 5e', 'Pathfinder'],
        friends: [],
        fellowships: [],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when onboarding completes successfully',
        build: () {
          when(
            () => mockCompleteOnboardingUseCase(
              userId: any(named: 'userId'),
              displayName: any(named: 'displayName'),
              bio: any(named: 'bio'),
              preferredSystems: any(named: 'preferredSystems'),
              experienceLevel: any(named: 'experienceLevel'),
            ),
          ).thenAnswer((_) async => updatedUser);

          // Mock the gamification service calls
          when(
            () => mockGamificationService.awardXp(any()),
          ).thenAnswer((_) async => null);

          return createAuthBloc();
        },
        seed: () => const AuthAuthenticated(
          user: testUserNeedsOnboarding,
          needsOnboarding: true,
        ),
        act: (bloc) => bloc.add(
          const AuthOnboardingCompleted(
            displayName: 'Updated User',
            bio: 'Updated bio',
            preferredSystems: ['D&D 5e', 'Pathfinder'],
            experienceLevel: 'Expert',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthOnboardingSuccess(
            xpAmount: 35,
            message: 'Your profile is all set!',
          ),
        ],
        verify: (_) {
          verify(
            () => mockCompleteOnboardingUseCase(
              userId: 'test-id',
              displayName: 'Updated User',
              bio: 'Updated bio',
              preferredSystems: ['D&D 5e', 'Pathfinder'],
              experienceLevel: 'Expert',
            ),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'does nothing when not in AuthAuthenticated state',
        build: () => createAuthBloc(),
        seed: () => const AuthUnauthenticated(),
        act: (bloc) => bloc.add(
          const AuthOnboardingCompleted(
            displayName: 'Updated User',
            preferredSystems: ['D&D 5e'],
            experienceLevel: 'Expert',
          ),
        ),
        expect: () => [],
        verify: (_) {
          verifyNever(
            () => mockCompleteOnboardingUseCase(
              userId: any(named: 'userId'),
              displayName: any(named: 'displayName'),
              bio: any(named: 'bio'),
              preferredSystems: any(named: 'preferredSystems'),
              experienceLevel: any(named: 'experienceLevel'),
            ),
          );
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when onboarding fails',
        build: () {
          when(
            () => mockCompleteOnboardingUseCase(
              userId: any(named: 'userId'),
              displayName: any(named: 'displayName'),
              bio: any(named: 'bio'),
              preferredSystems: any(named: 'preferredSystems'),
              experienceLevel: any(named: 'experienceLevel'),
            ),
          ).thenThrow(Exception('Onboarding failed'));
          return createAuthBloc();
        },
        seed: () => const AuthAuthenticated(
          user: testUserNeedsOnboarding,
          needsOnboarding: true,
        ),
        act: (bloc) => bloc.add(
          const AuthOnboardingCompleted(
            displayName: 'Updated User',
            preferredSystems: ['D&D 5e'],
            experienceLevel: 'Expert',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Exception: Onboarding failed'),
        ],
      );
    });

    group('Race Condition Prevention', () {
      blocTest<AuthBloc, AuthState>(
        'sign in does not manually trigger AuthStarted - only stream handles state changes',
        build: () {
          when(
            () => mockSignInUseCase(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer((_) async => testUser);
          return createAuthBloc();
        },
        act: (bloc) async {
          bloc.add(
            const AuthSignInRequested(
              email: 'test@example.com',
              password: 'password',
            ),
          );
          await Future.delayed(const Duration(milliseconds: 100));
          // Simulate auth state stream change
          authStateController.add(testUser);
        },
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(user: testUser, needsOnboarding: false),
        ],
        verify: (_) {
          verify(
            () => mockSignInUseCase(
              email: 'test@example.com',
              password: 'password',
            ),
          ).called(1);
          // Verify no additional calls to getCurrentUser from manual AuthStarted
          verifyNever(() => mockGetCurrentUserUseCase());
        },
      );
    });
  });
}
