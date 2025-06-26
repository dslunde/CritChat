import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';

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
import 'package:critchat/features/fellowships/presentation/widgets/fellowship_card.dart';
import 'package:critchat/features/auth/domain/entities/user_entity.dart';

// Mock classes
class MockFellowshipRepository extends Mock implements FellowshipRepository {}

class MockGetFellowshipsUseCase extends Mock implements GetFellowshipsUseCase {}

class MockCreateFellowshipUseCase extends Mock
    implements CreateFellowshipUseCase {}

class MockInviteFriendUseCase extends Mock implements InviteFriendUseCase {}

void main() {
  group('Fellowship Feature Tests', () {
    late MockFellowshipRepository mockRepository;
    late MockGetFellowshipsUseCase mockGetFellowshipsUseCase;
    late MockCreateFellowshipUseCase mockCreateFellowshipUseCase;
    late MockInviteFriendUseCase mockInviteFriendUseCase;
    late FellowshipBloc fellowshipBloc;

    // Sample test data
    final testUser = UserEntity(
      id: '1',
      email: 'test@test.com',
      displayName: 'Test User',
      bio: 'Test bio',
      experienceLevel: 'Veteran',
      preferredSystems: ['D&D 5e'],
      totalXp: 100,
      joinedGroups: ['fellowship1'],
    );

    final testFellowship = FellowshipEntity(
      id: 'fellowship1',
      name: 'The Brave Adventurers',
      description: 'A fellowship of brave heroes',
      creatorId: '1',
      memberIds: ['1', '2'],
      gameSystem: 'D&D 5e',
      isPublic: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockRepository = MockFellowshipRepository();
      mockGetFellowshipsUseCase = MockGetFellowshipsUseCase();
      mockCreateFellowshipUseCase = MockCreateFellowshipUseCase();
      mockInviteFriendUseCase = MockInviteFriendUseCase();

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
          equals('A fellowship of brave heroes'),
        );
        expect(testFellowship.creatorId, equals('1'));
        expect(testFellowship.memberIds, contains('1'));
        expect(testFellowship.gameSystem, equals('D&D 5e'));
        expect(testFellowship.isPublic, isTrue);
      });

      test('should correctly identify creator', () {
        expect(testFellowship.isCreator('1'), isTrue);
        expect(testFellowship.isCreator('2'), isFalse);
      });

      test('should correctly identify members', () {
        expect(testFellowship.isMember('1'), isTrue);
        expect(testFellowship.isMember('2'), isTrue);
        expect(testFellowship.isMember('3'), isFalse);
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
          ).thenAnswer((_) async => [testFellowship]);
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(GetFellowships()),
        expect: () => [
          FellowshipLoading(),
          FellowshipLoaded([testFellowship]),
        ],
      );

      blocTest<FellowshipBloc, FellowshipState>(
        'should emit [FellowshipLoading, FellowshipError] when GetFellowships fails',
        build: () {
          when(
            () => mockGetFellowshipsUseCase(),
          ).thenThrow(Exception('Failed to get fellowships'));
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(GetFellowships()),
        expect: () => [
          FellowshipLoading(),
          FellowshipError('Failed to get fellowships'),
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
    });

    group('Fellowship UI Tests', () {
      testWidgets('FellowshipsPage should display loading indicator', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(MaterialApp(home: FellowshipsPage()));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('FellowshipCard should display fellowship information', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: FellowshipCard(fellowship: testFellowship)),
          ),
        );

        expect(find.text('The Brave Adventurers'), findsOneWidget);
        expect(find.text('A fellowship of brave heroes'), findsOneWidget);
        expect(find.text('D&D 5e'), findsOneWidget);
        expect(find.text('2 members'), findsOneWidget);
      });

      testWidgets('CreateFellowshipPage should display form fields', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(MaterialApp(home: CreateFellowshipPage()));

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

      testWidgets(
        'should navigate to create fellowship page when FAB is pressed',
        (WidgetTester tester) async {
          await tester.pumpWidget(MaterialApp(home: FellowshipsPage()));

          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();

          expect(find.byType(CreateFellowshipPage), findsOneWidget);
        },
      );
    });
  });
}
