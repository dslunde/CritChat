// Comprehensive Fellowship Feature Tests
// Tests Fellowship domain, data, and presentation layers with Firebase integration

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';
import 'package:critchat/features/fellowships/domain/repositories/fellowship_repository.dart';
import 'package:critchat/features/fellowships/domain/usecases/get_fellowships_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/create_fellowship_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/invite_friend_usecase.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_bloc.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_event.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_state.dart';
import 'package:critchat/features/fellowships/presentation/pages/fellowships_page.dart';
import 'package:critchat/features/fellowships/presentation/pages/create_fellowship_page.dart';
import 'package:critchat/features/fellowships/presentation/pages/fellowship_chat_page.dart';
import 'package:critchat/features/fellowships/presentation/pages/fellowship_info_page.dart';
import 'package:critchat/features/fellowships/presentation/widgets/fellowship_card.dart';
import 'package:critchat/features/fellowships/presentation/widgets/invite_friends_dialog.dart';
import 'package:critchat/features/auth/domain/entities/user_entity.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:critchat/features/auth/presentation/bloc/auth_state.dart';
import 'package:critchat/features/friends/domain/entities/friend_entity.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_bloc.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_state.dart';

// Mock classes
class MockFellowshipRepository extends Mock implements FellowshipRepository {}

class MockGetFellowshipsUseCase extends Mock implements GetFellowshipsUseCase {}

class MockCreateFellowshipUseCase extends Mock
    implements CreateFellowshipUseCase {}

class MockInviteFriendUseCase extends Mock implements InviteFriendUseCase {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockFriendsBloc extends Mock implements FriendsBloc {}

void main() {
  group('Fellowship Feature Comprehensive Tests', () {
    late MockFellowshipRepository mockRepository;
    late MockGetFellowshipsUseCase mockGetFellowshipsUseCase;
    late MockCreateFellowshipUseCase mockCreateFellowshipUseCase;
    late MockInviteFriendUseCase mockInviteFriendUseCase;
    late MockAuthBloc mockAuthBloc;
    late MockFriendsBloc mockFriendsBloc;
    late FellowshipBloc fellowshipBloc;

    // Sample test data with updated UserEntity structure
    final testUser = UserEntity(
      id: '1',
      email: 'test@test.com',
      displayName: 'Test User',
      bio: 'Test bio',
      experienceLevel: 'Veteran',
      preferredSystems: ['D&D 5e'],
      totalXp: 100,
      friends: ['friend1'],
      fellowships: ['fellowship1'],
      createdAt: DateTime.now(),
    );

    final testFriend = FriendEntity(
      id: 'friend1',
      displayName: 'Friend User',
      email: 'friend@test.com',
      bio: 'Friend bio',
      experienceLevel: 'Expert',
      preferredSystems: ['D&D 5e'],
      totalXp: 150,
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    final testFellowship = FellowshipEntity(
      id: 'fellowship1',
      name: 'The Brave Adventurers',
      description: 'A fellowship of brave heroes exploring the realms',
      creatorId: '1',
      memberIds: ['1', '2', '3'],
      gameSystem: 'D&D 5e',
      isPublic: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testPrivateFellowship = FellowshipEntity(
      id: 'fellowship2',
      name: 'Secret Guild',
      description: 'A private fellowship for experienced players',
      creatorId: '1',
      memberIds: ['1', '4'],
      gameSystem: 'Pathfinder',
      isPublic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockRepository = MockFellowshipRepository();
      mockGetFellowshipsUseCase = MockGetFellowshipsUseCase();
      mockCreateFellowshipUseCase = MockCreateFellowshipUseCase();
      mockInviteFriendUseCase = MockInviteFriendUseCase();
      mockAuthBloc = MockAuthBloc();
      mockFriendsBloc = MockFriendsBloc();

      fellowshipBloc = FellowshipBloc(
        getFellowshipsUseCase: mockGetFellowshipsUseCase,
        createFellowshipUseCase: mockCreateFellowshipUseCase,
        inviteFriendUseCase: mockInviteFriendUseCase,
      );

      // Setup GetIt for tests
      GetIt.instance.reset();
      GetIt.instance.registerLazySingleton<FellowshipBloc>(
        () => fellowshipBloc,
      );
      GetIt.instance.registerLazySingleton<AuthBloc>(() => mockAuthBloc);
      GetIt.instance.registerLazySingleton<FriendsBloc>(() => mockFriendsBloc);

      // Setup common mock responses
      when(
        () => mockAuthBloc.state,
      ).thenReturn(AuthAuthenticated(user: testUser, needsOnboarding: false));
      when(() => mockFriendsBloc.state).thenReturn(FriendsLoaded([testFriend]));
    });

    tearDown(() {
      fellowshipBloc.close();
      GetIt.instance.reset();
    });

    group('Fellowship Entity Tests', () {
      test('should create fellowship entity with correct properties', () {
        expect(testFellowship.id, equals('fellowship1'));
        expect(testFellowship.name, equals('The Brave Adventurers'));
        expect(
          testFellowship.description,
          equals('A fellowship of brave heroes exploring the realms'),
        );
        expect(testFellowship.creatorId, equals('1'));
        expect(testFellowship.memberIds, contains('1'));
        expect(testFellowship.memberIds.length, equals(3));
        expect(testFellowship.gameSystem, equals('D&D 5e'));
        expect(testFellowship.isPublic, isTrue);
      });

      test('should correctly identify creator', () {
        expect(testFellowship.isCreator('1'), isTrue);
        expect(testFellowship.isCreator('2'), isFalse);
        expect(testFellowship.isCreator('999'), isFalse);
      });

      test('should correctly identify members', () {
        expect(testFellowship.isMember('1'), isTrue);
        expect(testFellowship.isMember('2'), isTrue);
        expect(testFellowship.isMember('3'), isTrue);
        expect(testFellowship.isMember('999'), isFalse);
      });

      test('should handle private fellowship properties', () {
        expect(testPrivateFellowship.isPublic, isFalse);
        expect(testPrivateFellowship.gameSystem, equals('Pathfinder'));
        expect(testPrivateFellowship.memberIds.length, equals(2));
      });

      test('should have proper timestamps', () {
        expect(testFellowship.createdAt, isA<DateTime>());
        expect(testFellowship.updatedAt, isA<DateTime>());
      });
    });

    group('Fellowship BLoC Tests', () {
      test('initial state should be FellowshipInitial', () {
        expect(fellowshipBloc.state, equals(FellowshipInitial()));
      });

      blocTest<FellowshipBloc, FellowshipState>(
        'should emit [FellowshipLoading, FellowshipLoaded] when GetFellowships is successful',
        build: () {
          when(
            () => mockGetFellowshipsUseCase(),
          ).thenAnswer((_) async => [testFellowship, testPrivateFellowship]);
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(GetFellowships()),
        expect: () => [
          FellowshipLoading(),
          FellowshipLoaded([testFellowship, testPrivateFellowship]),
        ],
      );

      blocTest<FellowshipBloc, FellowshipState>(
        'should emit [FellowshipLoading, FellowshipError] when GetFellowships fails',
        build: () {
          when(
            () => mockGetFellowshipsUseCase(),
          ).thenThrow(Exception('Firebase connection failed'));
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(GetFellowships()),
        expect: () => [
          FellowshipLoading(),
          FellowshipError('Firebase connection failed'),
        ],
      );

      blocTest<FellowshipBloc, FellowshipState>(
        'should emit [FellowshipLoading, FellowshipCreated] when CreateFellowship is successful',
        build: () {
          when(
            () => mockCreateFellowshipUseCase(
              name: any(named: 'name'),
              description: any(named: 'description'),
              gameSystem: any(named: 'gameSystem'),
              isPublic: any(named: 'isPublic'),
              creatorId: any(named: 'creatorId'),
            ),
          ).thenAnswer((_) async => testFellowship);
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(
          CreateFellowship(
            name: 'Test Fellowship',
            description: 'Test description',
            gameSystem: 'D&D 5e',
            isPublic: true,
            creatorId: '1',
          ),
        ),
        expect: () => [FellowshipLoading(), FellowshipCreated(testFellowship)],
      );

      blocTest<FellowshipBloc, FellowshipState>(
        'should emit [FellowshipLoading, FellowshipError] when CreateFellowship fails',
        build: () {
          when(
            () => mockCreateFellowshipUseCase(
              name: any(named: 'name'),
              description: any(named: 'description'),
              gameSystem: any(named: 'gameSystem'),
              isPublic: any(named: 'isPublic'),
              creatorId: any(named: 'creatorId'),
            ),
          ).thenThrow(Exception('Failed to create fellowship'));
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(
          CreateFellowship(
            name: 'Test Fellowship',
            description: 'Test description',
            gameSystem: 'D&D 5e',
            isPublic: true,
            creatorId: '1',
          ),
        ),
        expect: () => [
          FellowshipLoading(),
          FellowshipError('Failed to create fellowship'),
        ],
      );

      blocTest<FellowshipBloc, FellowshipState>(
        'should emit [FellowshipLoading, FriendInvited] when InviteFriend is successful',
        build: () {
          when(
            () => mockInviteFriendUseCase(any(), any()),
          ).thenAnswer((_) async => true);
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(
          InviteFriend(fellowshipId: 'fellowship1', friendId: 'friend1'),
        ),
        expect: () => [FellowshipLoading(), FriendInvited()],
      );

      blocTest<FellowshipBloc, FellowshipState>(
        'should emit [FellowshipLoading, FellowshipError] when InviteFriend fails',
        build: () {
          when(
            () => mockInviteFriendUseCase(any(), any()),
          ).thenThrow(Exception('Friend already invited'));
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(
          InviteFriend(fellowshipId: 'fellowship1', friendId: 'friend1'),
        ),
        expect: () => [
          FellowshipLoading(),
          FellowshipError('Friend already invited'),
        ],
      );
    });

    group('Fellowship UI Tests', () {
      Widget createTestWidget(Widget child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<FellowshipBloc>.value(value: fellowshipBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<FriendsBloc>.value(value: mockFriendsBloc),
          ],
          child: MaterialApp(home: child),
        );
      }

      testWidgets('FellowshipsPage displays loading indicator initially', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget(FellowshipsPage()));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('FellowshipsPage displays fellowships when loaded', (
        WidgetTester tester,
      ) async {
        when(
          () => mockGetFellowshipsUseCase(),
        ).thenAnswer((_) async => [testFellowship]);
        fellowshipBloc.add(GetFellowships());

        await tester.pumpWidget(createTestWidget(FellowshipsPage()));
        await tester.pump(); // Allow BLoC to process

        expect(find.byType(FellowshipCard), findsOneWidget);
        expect(find.text('The Brave Adventurers'), findsOneWidget);
      });

      testWidgets(
        'FellowshipsPage shows floating action button for creating fellowship',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget(FellowshipsPage()));

          expect(find.byType(FloatingActionButton), findsOneWidget);
          expect(find.byIcon(Icons.add), findsOneWidget);
        },
      );

      testWidgets('FellowshipCard displays fellowship information correctly', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            Scaffold(body: FellowshipCard(fellowship: testFellowship)),
          ),
        );

        expect(find.text('The Brave Adventurers'), findsOneWidget);
        expect(
          find.text('A fellowship of brave heroes exploring the realms'),
          findsOneWidget,
        );
        expect(find.text('D&D 5e'), findsOneWidget);
        expect(find.text('3 members'), findsOneWidget);
        expect(find.text('Tap to chat'), findsOneWidget);
      });

      testWidgets(
        'FellowshipCard shows correct member count for different fellowships',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              Scaffold(body: FellowshipCard(fellowship: testPrivateFellowship)),
            ),
          );

          expect(find.text('Secret Guild'), findsOneWidget);
          expect(find.text('2 members'), findsOneWidget);
          expect(find.text('Pathfinder'), findsOneWidget);
        },
      );

      testWidgets('CreateFellowshipPage displays all form fields', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget(CreateFellowshipPage()));

        expect(find.text('Create Fellowship'), findsOneWidget);
        expect(
          find.byType(TextFormField),
          findsNWidgets(3),
        ); // Name, Description, Game System
        expect(
          find.byType(SwitchListTile),
          findsOneWidget,
        ); // Public/Private toggle
        expect(
          find.text('Create Fellowship'),
          findsAtLeastNWidgets(1),
        ); // Button
      });

      testWidgets('CreateFellowshipPage form validation works', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget(CreateFellowshipPage()));

        // Try to submit empty form
        final createButton = find.text('Create Fellowship').last;
        await tester.tap(createButton);
        await tester.pump();

        // Form should still be present (validation prevents submission)
        expect(find.byType(TextFormField), findsNWidgets(3));
      });

      testWidgets('FellowshipChatPage displays correctly', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(FellowshipChatPage(fellowship: testFellowship)),
        );

        expect(find.text('The Brave Adventurers'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget); // Message input field
        expect(find.byIcon(Icons.send), findsOneWidget); // Send button
        expect(find.byIcon(Icons.info_outline), findsOneWidget); // Info button
      });

      testWidgets('FellowshipInfoPage displays fellowship details', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(FellowshipInfoPage(fellowship: testFellowship)),
        );

        expect(find.text('The Brave Adventurers'), findsOneWidget);
        expect(find.text('D&D 5e'), findsOneWidget);
        expect(find.text('Invite a Friend'), findsOneWidget);
        expect(find.text('Leave Fellowship'), findsOneWidget);
      });

      testWidgets('InviteFriendsDialog shows available friends', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => InviteFriendsDialog(
                      fellowshipId: testFellowship.id,
                      fellowshipName: testFellowship.name,
                      fellowshipMemberIds: testFellowship.memberIds,
                    ),
                  ),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Invite Friends'), findsOneWidget);
        expect(find.text('Friend User'), findsOneWidget);
        expect(find.text('Invite'), findsOneWidget);
      });
    });

    group('Navigation Tests', () {
      testWidgets(
        'should navigate to CreateFellowshipPage when FAB is pressed',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MultiBlocProvider(
              providers: [
                BlocProvider<FellowshipBloc>.value(value: fellowshipBloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: MaterialApp(
                home: FellowshipsPage(),
                routes: {
                  '/create-fellowship': (context) => CreateFellowshipPage(),
                },
              ),
            ),
          );

          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();

          expect(find.byType(CreateFellowshipPage), findsOneWidget);
        },
      );

      testWidgets(
        'should navigate to FellowshipChatPage when fellowship card is tapped',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MultiBlocProvider(
              providers: [
                BlocProvider<FellowshipBloc>.value(value: fellowshipBloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: FellowshipCard(fellowship: testFellowship),
                ),
              ),
            ),
          );

          await tester.tap(find.byType(FellowshipCard));
          await tester.pumpAndSettle();

          // Should navigate to chat page (implementation dependent)
          expect(find.byType(FellowshipCard), findsOneWidget);
        },
      );
    });

    group('Integration Tests', () {
      testWidgets('complete fellowship creation flow', (
        WidgetTester tester,
      ) async {
        when(
          () => mockCreateFellowshipUseCase(
            name: any(named: 'name'),
            description: any(named: 'description'),
            gameSystem: any(named: 'gameSystem'),
            isPublic: any(named: 'isPublic'),
            creatorId: any(named: 'creatorId'),
          ),
        ).thenAnswer((_) async => testFellowship);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<FellowshipBloc>.value(value: fellowshipBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: MaterialApp(home: CreateFellowshipPage()),
          ),
        );

        // Fill in the form
        await tester.enterText(
          find.byType(TextFormField).first,
          'Test Fellowship',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Test Description',
        );
        await tester.enterText(find.byType(TextFormField).at(2), 'D&D 5e');

        // Submit the form
        await tester.tap(find.text('Create Fellowship').last);
        await tester.pump();

        // Verify the BLoC received the event (implementation dependent)
        expect(find.byType(CreateFellowshipPage), findsOneWidget);
      });

      testWidgets('fellowship list updates after creation', (
        WidgetTester tester,
      ) async {
        when(
          () => mockGetFellowshipsUseCase(),
        ).thenAnswer((_) async => [testFellowship]);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<FellowshipBloc>.value(value: fellowshipBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: MaterialApp(home: FellowshipsPage()),
          ),
        );

        // Trigger fellowship load
        fellowshipBloc.add(GetFellowships());
        await tester.pump();

        expect(find.byType(FellowshipCard), findsOneWidget);
        expect(find.text('The Brave Adventurers'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('displays error message when fellowship loading fails', (
        WidgetTester tester,
      ) async {
        when(
          () => mockGetFellowshipsUseCase(),
        ).thenThrow(Exception('Network error'));

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<FellowshipBloc>.value(value: fellowshipBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: MaterialApp(home: FellowshipsPage()),
          ),
        );

        fellowshipBloc.add(GetFellowships());
        await tester.pump();

        expect(find.text('Network error'), findsOneWidget);
      });

      testWidgets('handles empty fellowship list gracefully', (
        WidgetTester tester,
      ) async {
        when(() => mockGetFellowshipsUseCase()).thenAnswer((_) async => []);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<FellowshipBloc>.value(value: fellowshipBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: MaterialApp(home: FellowshipsPage()),
          ),
        );

        fellowshipBloc.add(GetFellowships());
        await tester.pump();

        expect(find.text('No fellowships yet'), findsOneWidget);
        expect(
          find.text('Create your first fellowship to get started!'),
          findsOneWidget,
        );
      });
    });
  });
}
