// Comprehensive Fellowship Feature Tests
// Tests Fellowship domain, data, and presentation layers with Firebase integration

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';
import 'package:critchat/features/fellowships/domain/repositories/fellowship_repository.dart';
import 'package:critchat/features/fellowships/domain/usecases/get_fellowships_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/create_fellowship_usecase.dart';
import 'package:critchat/features/fellowships/domain/usecases/invite_friend_usecase.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_bloc.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_event.dart';
import 'package:critchat/features/fellowships/presentation/bloc/fellowship_state.dart';

// Mock classes
class MockFellowshipRepository extends Mock implements FellowshipRepository {}

class MockGetFellowshipsUseCase extends Mock implements GetFellowshipsUseCase {}

class MockCreateFellowshipUseCase extends Mock
    implements CreateFellowshipUseCase {}

class MockInviteFriendUseCase extends Mock implements InviteFriendUseCase {}

void main() {
  group('Fellowship Feature Comprehensive Tests', () {
    late MockFellowshipRepository mockRepository;
    late MockGetFellowshipsUseCase mockGetFellowshipsUseCase;
    late MockCreateFellowshipUseCase mockCreateFellowshipUseCase;
    late MockInviteFriendUseCase mockInviteFriendUseCase;
    late FellowshipBloc fellowshipBloc;

    // Sample test data with updated UserEntity structure

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

      fellowshipBloc = FellowshipBloc(
        getFellowshipsUseCase: mockGetFellowshipsUseCase,
        createFellowshipUseCase: mockCreateFellowshipUseCase,
        inviteFriendUseCase: mockInviteFriendUseCase,
      );
    });

    tearDown(() {
      fellowshipBloc.close();
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
          ).thenThrow(Exception('Failed to load fellowships'));
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(GetFellowships()),
        expect: () => [
          FellowshipLoading(),
          FellowshipError('Failed to get fellowships'),
        ],
      );

      blocTest<FellowshipBloc, FellowshipState>(
        'should emit [FellowshipLoading, FellowshipLoaded] with empty list when no fellowships',
        build: () {
          when(() => mockGetFellowshipsUseCase()).thenAnswer((_) async => []);
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(GetFellowships()),
        expect: () => [FellowshipLoading(), FellowshipLoaded([])],
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
            description: 'Test Description',
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
            description: 'Test Description',
            gameSystem: 'D&D 5e',
            isPublic: true,
            creatorId: '1',
          ),
        ),
        expect: () => [
          FellowshipLoading(),
          FellowshipError(
            'Failed to create fellowship: Exception: Failed to create fellowship',
          ),
        ],
      );

      blocTest<FellowshipBloc, FellowshipState>(
        'should emit [FellowshipLoading, FriendInvited] when InviteFriend is successful',
        build: () {
          when(
            () => mockInviteFriendUseCase(any(), any()),
          ).thenAnswer((_) async => true);
          when(() => mockGetFellowshipsUseCase()).thenAnswer((_) async => []);
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(
          InviteFriend(fellowshipId: 'fellowship1', friendId: 'friend1'),
        ),
        expect: () => [
          FellowshipLoading(),
          FriendInvited(),
          FellowshipLoading(),
          FellowshipLoaded([]),
        ],
      );

      blocTest<FellowshipBloc, FellowshipState>(
        'should emit [FellowshipLoading, FellowshipError] when InviteFriend fails',
        build: () {
          when(
            () => mockInviteFriendUseCase(any(), any()),
          ).thenThrow(Exception('Failed to invite friend'));
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(
          InviteFriend(fellowshipId: 'fellowship1', friendId: 'friend1'),
        ),
        expect: () => [
          FellowshipLoading(),
          FellowshipError('Failed to invite friend'),
        ],
      );
    });

    group('Use Cases Tests', () {
      test('GetFellowshipsUseCase should call repository', () async {
        // Arrange
        when(
          () => mockRepository.getFellowships(),
        ).thenAnswer((_) async => [testFellowship]);
        final useCase = GetFellowshipsUseCase(repository: mockRepository);

        // Act
        final result = await useCase();

        // Assert
        expect(result, equals([testFellowship]));
        verify(() => mockRepository.getFellowships()).called(1);
      });

      test(
        'CreateFellowshipUseCase should call repository with correct parameters',
        () async {
          // Arrange
          when(
            () => mockRepository.createFellowship(
              name: any(named: 'name'),
              description: any(named: 'description'),
              gameSystem: any(named: 'gameSystem'),
              isPublic: any(named: 'isPublic'),
              creatorId: any(named: 'creatorId'),
            ),
          ).thenAnswer((_) async => testFellowship);
          final useCase = CreateFellowshipUseCase(repository: mockRepository);

          // Act
          final result = await useCase(
            name: 'Test Fellowship',
            description: 'Test Description',
            gameSystem: 'D&D 5e',
            isPublic: true,
            creatorId: '1',
          );

          // Assert
          expect(result, equals(testFellowship));
          verify(
            () => mockRepository.createFellowship(
              name: 'Test Fellowship',
              description: 'Test Description',
              gameSystem: 'D&D 5e',
              isPublic: true,
              creatorId: '1',
            ),
          ).called(1);
        },
      );

      test(
        'InviteFriendUseCase should call repository with correct parameters',
        () async {
          // Arrange
          when(
            () => mockRepository.inviteFriendToFellowship(any(), any()),
          ).thenAnswer((_) async => true);
          final useCase = InviteFriendUseCase(repository: mockRepository);

          // Act
          final result = await useCase('fellowship1', 'friend1');

          // Assert
          expect(result, isTrue);
          verify(
            () => mockRepository.inviteFriendToFellowship(
              'fellowship1',
              'friend1',
            ),
          ).called(1);
        },
      );
    });

    group('Error Handling Tests', () {
      blocTest<FellowshipBloc, FellowshipState>(
        'should handle repository errors gracefully',
        build: () {
          when(
            () => mockGetFellowshipsUseCase(),
          ).thenThrow(Exception('Database error'));
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(GetFellowships()),
        expect: () => [
          FellowshipLoading(),
          FellowshipError('Failed to get fellowships'),
        ],
      );

      blocTest<FellowshipBloc, FellowshipState>(
        'should handle network errors during fellowship creation',
        build: () {
          when(
            () => mockCreateFellowshipUseCase(
              name: any(named: 'name'),
              description: any(named: 'description'),
              gameSystem: any(named: 'gameSystem'),
              isPublic: any(named: 'isPublic'),
              creatorId: any(named: 'creatorId'),
            ),
          ).thenThrow(Exception('Network connection failed'));
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(
          CreateFellowship(
            name: 'Test Fellowship',
            description: 'Test Description',
            gameSystem: 'D&D 5e',
            isPublic: true,
            creatorId: '1',
          ),
        ),
        expect: () => [
          FellowshipLoading(),
          FellowshipError(
            'Failed to create fellowship: Exception: Network connection failed',
          ),
        ],
      );

      blocTest<FellowshipBloc, FellowshipState>(
        'should handle friend invitation errors',
        build: () {
          when(
            () => mockInviteFriendUseCase(any(), any()),
          ).thenThrow(Exception('Friend invitation failed'));
          return fellowshipBloc;
        },
        act: (bloc) => bloc.add(
          InviteFriend(fellowshipId: 'fellowship1', friendId: 'friend1'),
        ),
        expect: () => [
          FellowshipLoading(),
          FellowshipError('Failed to invite friend'),
        ],
      );
    });

    group('Integration Tests', () {
      test('fellowship entity should support all game systems', () {
        final gameSystems = [
          'D&D 5e',
          'Pathfinder',
          'Call of Cthulhu',
          'Vampire: The Masquerade',
        ];

        for (final system in gameSystems) {
          final fellowship = FellowshipEntity(
            id: 'test',
            name: 'Test Fellowship',
            description: 'Test Description',
            creatorId: '1',
            memberIds: ['1'],
            gameSystem: system,
            isPublic: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          expect(fellowship.gameSystem, equals(system));
        }
      });

      test('fellowship should handle multiple members correctly', () {
        final manyMembersFellowship = FellowshipEntity(
          id: 'fellowship_many',
          name: 'Large Fellowship',
          description: 'A fellowship with many members',
          creatorId: '1',
          memberIds: ['1', '2', '3', '4', '5', '6', '7', '8'],
          gameSystem: 'D&D 5e',
          isPublic: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(manyMembersFellowship.memberIds.length, equals(8));
        expect(manyMembersFellowship.isCreator('1'), isTrue);
        expect(manyMembersFellowship.isMember('8'), isTrue);
        expect(manyMembersFellowship.isMember('9'), isFalse);
      });

      blocTest<FellowshipBloc, FellowshipState>(
        'should handle multiple sequential operations',
        build: () {
          when(
            () => mockGetFellowshipsUseCase(),
          ).thenAnswer((_) async => [testFellowship]);
          when(
            () => mockCreateFellowshipUseCase(
              name: any(named: 'name'),
              description: any(named: 'description'),
              gameSystem: any(named: 'gameSystem'),
              isPublic: any(named: 'isPublic'),
              creatorId: any(named: 'creatorId'),
            ),
          ).thenAnswer((_) async => testPrivateFellowship);
          return fellowshipBloc;
        },
        act: (bloc) async {
          bloc.add(GetFellowships());
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(
            CreateFellowship(
              name: 'New Fellowship',
              description: 'New Description',
              gameSystem: 'Pathfinder',
              isPublic: false,
              creatorId: '1',
            ),
          );
        },
        expect: () => [
          FellowshipLoading(),
          FellowshipLoaded([testFellowship]),
          FellowshipLoading(),
          FellowshipCreated(testPrivateFellowship),
        ],
      );
    });
  });
}
