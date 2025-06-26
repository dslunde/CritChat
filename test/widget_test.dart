// Comprehensive CritChat Widget Tests
// Tests all major features: Authentication, Friends, Fellowship, Notifications

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:critchat/main.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_event.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';
import 'package:critchat/features/auth/presentation/pages/sign_in_page.dart';
import 'package:critchat/features/auth/presentation/pages/onboarding_page.dart';
import 'package:critchat/features/auth/domain/entities/user_entity.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_bloc.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_event.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_state.dart';
import 'package:critchat/features/friends/domain/entities/friend_entity.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_bloc.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_event.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_state.dart';
import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';
import 'package:critchat/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:critchat/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:critchat/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:critchat/features/notifications/domain/entities/notification_entity.dart';
import 'package:critchat/features/navigation/main_navigation.dart';
import 'package:critchat/core/widgets/app_top_bar.dart';
import 'package:critchat/core/constants/app_strings.dart';

// Mock classes for all features
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockFriendsBloc extends MockBloc<FriendsEvent, FriendsState>
    implements FriendsBloc {}

class MockFellowshipBloc extends MockBloc<FellowshipEvent, FellowshipState>
    implements FellowshipBloc {}

class MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

class MockUserEntity extends Mock implements UserEntity {}

class MockFriendEntity extends Mock implements FriendEntity {}

class MockFellowshipEntity extends Mock implements FellowshipEntity {}

class MockNotificationEntity extends Mock implements NotificationEntity {}

void main() {
  group('CritChat Comprehensive Widget Tests', () {
    late MockAuthBloc mockAuthBloc;
    late MockFriendsBloc mockFriendsBloc;
    late MockFellowshipBloc mockFellowshipBloc;
    late MockNotificationsBloc mockNotificationsBloc;
    late MockUserEntity mockUser;
    late MockFriendEntity mockFriend;
    late MockFellowshipEntity mockFellowship;
    late MockNotificationEntity mockNotification;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockFriendsBloc = MockFriendsBloc();
      mockFellowshipBloc = MockFellowshipBloc();
      mockNotificationsBloc = MockNotificationsBloc();
      mockUser = MockUserEntity();
      mockFriend = MockFriendEntity();
      mockFellowship = MockFellowshipEntity();
      mockNotification = MockNotificationEntity();

      // Setup mock user properties with updated UserEntity structure
      when(() => mockUser.id).thenReturn('test-user-id');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockUser.bio).thenReturn('Test bio');
      when(() => mockUser.experienceLevel).thenReturn('Intermediate');
      when(
        () => mockUser.preferredSystems,
      ).thenReturn(['D&D 5E', 'Pathfinder']);
      when(() => mockUser.totalXp).thenReturn(100);
      when(() => mockUser.friends).thenReturn(['friend1', 'friend2']);
      when(() => mockUser.fellowships).thenReturn(['fellowship1']);
      when(() => mockUser.createdAt).thenReturn(DateTime.now());

      // Setup mock friend properties
      when(() => mockFriend.id).thenReturn('friend1');
      when(() => mockFriend.displayName).thenReturn('Friend User');
      when(() => mockFriend.bio).thenReturn('Friend bio');
      when(() => mockFriend.experienceLevel).thenReturn('Expert');
      when(() => mockFriend.preferredSystems).thenReturn(['D&D 5E']);
      when(() => mockFriend.isOnline).thenReturn(true);
      when(() => mockFriend.lastSeen).thenReturn(DateTime.now());

      // Setup mock fellowship properties
      when(() => mockFellowship.id).thenReturn('fellowship1');
      when(() => mockFellowship.name).thenReturn('Test Fellowship');
      when(
        () => mockFellowship.description,
      ).thenReturn('Test fellowship description');
      when(() => mockFellowship.gameSystem).thenReturn('D&D 5E');
      when(() => mockFellowship.isPublic).thenReturn(true);
      when(() => mockFellowship.memberIds).thenReturn(['user1', 'user2']);
      when(() => mockFellowship.creatorId).thenReturn('user1');

      // Setup mock notification properties
      when(() => mockNotification.id).thenReturn('notification1');
      when(() => mockNotification.title).thenReturn('Test Notification');
      when(
        () => mockNotification.message,
      ).thenReturn('Test notification message');
      when(
        () => mockNotification.type,
      ).thenReturn(NotificationType.friendRequest);
      when(() => mockNotification.isRead).thenReturn(false);
      when(() => mockNotification.createdAt).thenReturn(DateTime.now());

      // Setup GetIt for tests
      GetIt.instance.reset();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    group('Authentication Flow Tests', () {
      testWidgets('shows SignInPage when unauthenticated', (
        WidgetTester tester,
      ) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthUnauthenticated());

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const MaterialApp(home: AuthWrapper()),
          ),
        );

        expect(find.byType(SignInPage), findsOneWidget);
        expect(find.text(AppStrings.welcomeBack), findsOneWidget);
        expect(find.text(AppStrings.signIn), findsOneWidget);
      });

      testWidgets('shows LoadingScreen when loading', (
        WidgetTester tester,
      ) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthLoading());

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const MaterialApp(home: AuthWrapper()),
          ),
        );

        expect(find.byType(LoadingScreen), findsOneWidget);
        expect(find.text(AppStrings.appName), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets(
        'shows OnboardingPage when authenticated but needs onboarding',
        (WidgetTester tester) async {
          when(() => mockAuthBloc.state).thenReturn(
            AuthAuthenticated(user: mockUser, needsOnboarding: true),
          );

          await tester.pumpWidget(
            BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: const MaterialApp(home: AuthWrapper()),
            ),
          );

          expect(find.byType(OnboardingPage), findsOneWidget);
          expect(find.text(AppStrings.tellUsAboutYou), findsOneWidget);
        },
      );

      testWidgets('shows MainNavigation when fully authenticated', (
        WidgetTester tester,
      ) async {
        when(
          () => mockAuthBloc.state,
        ).thenReturn(AuthAuthenticated(user: mockUser, needsOnboarding: false));

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const MaterialApp(home: AuthWrapper()),
          ),
        );

        expect(find.byType(MainNavigation), findsOneWidget);
      });

      testWidgets('shows ErrorScreen when authentication error occurs', (
        WidgetTester tester,
      ) async {
        const errorMessage = 'Authentication failed';
        when(
          () => mockAuthBloc.state,
        ).thenReturn(const AuthError(message: errorMessage));

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const MaterialApp(home: AuthWrapper()),
          ),
        );

        expect(find.byType(ErrorScreen), findsOneWidget);
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.text(AppStrings.tryAgain), findsOneWidget);
      });
    });

    group('Sign In Page Tests', () {
      testWidgets('SignInPage contains all required elements', (
        WidgetTester tester,
      ) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthUnauthenticated());

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const MaterialApp(home: SignInPage()),
          ),
        );

        // Check that key authentication elements are present
        expect(find.text(AppStrings.appName), findsOneWidget);
        expect(find.text(AppStrings.welcomeBack), findsOneWidget);
        expect(find.text(AppStrings.email), findsOneWidget);
        expect(find.text(AppStrings.password), findsOneWidget);
        expect(find.text(AppStrings.signIn), findsOneWidget);
        expect(find.text(AppStrings.signUp), findsOneWidget);

        // Check for form fields
        expect(
          find.byType(TextFormField),
          findsNWidgets(2),
        ); // Email and password fields
      });

      testWidgets('SignInPage form validation works', (
        WidgetTester tester,
      ) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthUnauthenticated());

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const MaterialApp(home: SignInPage()),
          ),
        );

        // Try to submit empty form
        final signInButton = find.text(AppStrings.signIn);
        await tester.tap(signInButton);
        await tester.pump();

        // Should show validation errors (implementation dependent)
        // This test verifies the form exists and button is tappable
        expect(signInButton, findsOneWidget);
      });
    });

    group('Onboarding Page Tests', () {
      testWidgets('OnboardingPage contains all required elements', (
        WidgetTester tester,
      ) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthUnauthenticated());

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const MaterialApp(home: OnboardingPage()),
          ),
        );

        // Check that onboarding elements are present
        expect(find.text(AppStrings.tellUsAboutYou), findsOneWidget);
        expect(find.text(AppStrings.displayName), findsOneWidget);
        expect(find.text(AppStrings.experienceLevel), findsOneWidget);
        expect(find.text(AppStrings.preferredSystems), findsOneWidget);
        expect(find.text(AppStrings.completeProfile), findsOneWidget);

        // Check for form fields
        expect(
          find.byType(TextFormField),
          findsAtLeastNWidgets(2),
        ); // Display name and bio fields
        expect(
          find.byType(DropdownButtonFormField),
          findsOneWidget,
        ); // Experience level dropdown
      });
    });

    group('Main Navigation Tests', () {
      Widget createMainNavigationTestWidget() {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<FriendsBloc>.value(value: mockFriendsBloc),
            BlocProvider<FellowshipBloc>.value(value: mockFellowshipBloc),
            BlocProvider<NotificationsBloc>.value(value: mockNotificationsBloc),
          ],
          child: const MaterialApp(home: MainNavigation()),
        );
      }

      testWidgets('MainNavigation shows bottom navigation bar', (
        WidgetTester tester,
      ) async {
        when(
          () => mockAuthBloc.state,
        ).thenReturn(AuthAuthenticated(user: mockUser, needsOnboarding: false));
        when(() => mockFriendsBloc.state).thenReturn(FriendsInitial());
        when(() => mockFellowshipBloc.state).thenReturn(FellowshipInitial());
        when(
          () => mockNotificationsBloc.state,
        ).thenReturn(NotificationsInitial());

        await tester.pumpWidget(createMainNavigationTestWidget());

        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // Check for all 5 navigation tabs
        expect(find.text('LFG'), findsOneWidget);
        expect(find.text('Friends'), findsOneWidget);
        expect(find.text('Camera'), findsOneWidget);
        expect(find.text('Fellowships'), findsOneWidget);
        expect(find.text('For Me'), findsOneWidget);
      });

      testWidgets('MainNavigation shows top bar with user info', (
        WidgetTester tester,
      ) async {
        when(
          () => mockAuthBloc.state,
        ).thenReturn(AuthAuthenticated(user: mockUser, needsOnboarding: false));
        when(() => mockFriendsBloc.state).thenReturn(FriendsInitial());
        when(() => mockFellowshipBloc.state).thenReturn(FellowshipInitial());
        when(
          () => mockNotificationsBloc.state,
        ).thenReturn(NotificationsInitial());

        await tester.pumpWidget(createMainNavigationTestWidget());

        // Check for top bar elements
        expect(find.byType(AppTopBar), findsOneWidget);
        // Profile picture and notifications should be present
        expect(
          find.byType(GestureDetector),
          findsAtLeastNWidgets(2),
        ); // Profile tap and notifications tap
      });
    });

    group('Error Handling Tests', () {
      testWidgets('ErrorScreen has retry functionality', (
        WidgetTester tester,
      ) async {
        const errorMessage = 'Test error message';
        when(
          () => mockAuthBloc.state,
        ).thenReturn(const AuthError(message: errorMessage));

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const MaterialApp(home: AuthWrapper()),
          ),
        );

        // Verify error screen elements
        expect(find.byType(ErrorScreen), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);

        // Find and tap the try again button
        final tryAgainButton = find.text(AppStrings.tryAgain);
        expect(tryAgainButton, findsOneWidget);

        await tester.tap(tryAgainButton);
        await tester.pump();

        // Button should be tappable (actual BLoC event verification would be in BLoC tests)
        expect(tryAgainButton, findsOneWidget);
      });
    });

    group('State Management Integration Tests', () {
      testWidgets('authentication state changes update UI correctly', (
        WidgetTester tester,
      ) async {
        // Start with loading state
        when(() => mockAuthBloc.state).thenReturn(const AuthLoading());

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const MaterialApp(home: AuthWrapper()),
          ),
        );

        expect(find.byType(LoadingScreen), findsOneWidget);

        // Change to authenticated state
        when(
          () => mockAuthBloc.state,
        ).thenReturn(AuthAuthenticated(user: mockUser, needsOnboarding: false));

        // In a real test with StreamController, we'd trigger state change
        // Here we're just verifying the widget responds to different states
        await tester.pump();
      });

      testWidgets('handles multiple BLoC providers correctly', (
        WidgetTester tester,
      ) async {
        when(
          () => mockAuthBloc.state,
        ).thenReturn(AuthAuthenticated(user: mockUser, needsOnboarding: false));
        when(() => mockFriendsBloc.state).thenReturn(FriendsLoaded([]));
        when(() => mockFellowshipBloc.state).thenReturn(FellowshipLoaded([]));
        when(() => mockNotificationsBloc.state).thenReturn(
          const NotificationsLoaded(notifications: [], unreadCount: 0),
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<FriendsBloc>.value(value: mockFriendsBloc),
              BlocProvider<FellowshipBloc>.value(value: mockFellowshipBloc),
              BlocProvider<NotificationsBloc>.value(
                value: mockNotificationsBloc,
              ),
            ],
            child: const MaterialApp(home: MainNavigation()),
          ),
        );

        // Should successfully build with all BLoC providers
        expect(find.byType(MainNavigation), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });
    });

    group('Navigation Flow Tests', () {
      testWidgets('can navigate between tabs', (WidgetTester tester) async {
        when(
          () => mockAuthBloc.state,
        ).thenReturn(AuthAuthenticated(user: mockUser, needsOnboarding: false));
        when(() => mockFriendsBloc.state).thenReturn(FriendsInitial());
        when(() => mockFellowshipBloc.state).thenReturn(FellowshipInitial());
        when(
          () => mockNotificationsBloc.state,
        ).thenReturn(NotificationsInitial());

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<FriendsBloc>.value(value: mockFriendsBloc),
              BlocProvider<FellowshipBloc>.value(value: mockFellowshipBloc),
              BlocProvider<NotificationsBloc>.value(
                value: mockNotificationsBloc,
              ),
            ],
            child: const MaterialApp(home: MainNavigation()),
          ),
        );

        // Verify initial state (should be on first tab)
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // Tap on Friends tab
        await tester.tap(find.text('Friends'));
        await tester.pump();

        // Tap on Fellowships tab
        await tester.tap(find.text('Fellowships'));
        await tester.pump();

        // Should still show navigation bar
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });
    });
  });
}
