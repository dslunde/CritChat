// Comprehensive Friends and Notifications Feature Tests
// Tests Friends and Notifications domain, data, and presentation layers with Firebase integration

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:critchat/features/friends/domain/entities/friend_entity.dart';
import 'package:critchat/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:critchat/features/friends/domain/usecases/add_friend_usecase.dart';
import 'package:critchat/features/friends/domain/usecases/remove_friend_usecase.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_bloc.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_event.dart';
import 'package:critchat/features/friends/presentation/bloc/friends_state.dart';

import 'package:critchat/features/notifications/domain/entities/notification_entity.dart';
import 'package:critchat/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:critchat/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:critchat/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:critchat/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:critchat/core/services/notification_indicator_service.dart';

// Mock classes
class MockGetFriendsUseCase extends Mock implements GetFriendsUseCase {}

class MockAddFriendUseCase extends Mock implements AddFriendUseCase {}

class MockRemoveFriendUseCase extends Mock implements RemoveFriendUseCase {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class MockNotificationIndicatorService extends Mock
    implements NotificationIndicatorService {}

void main() {
  group('Friends and Notifications Comprehensive Tests', () {
    late MockGetFriendsUseCase mockGetFriendsUseCase;
    late MockNotificationsRepository mockNotificationsRepository;
    late FriendsBloc friendsBloc;
    late NotificationsBloc notificationsBloc;

    // Sample test data
    final testFriend1 = FriendEntity(
      id: 'friend1',
      displayName: 'Friend One',
      email: 'friend1@test.com',
      bio: 'First friend bio',
      experienceLevel: 'Expert',
      preferredSystems: ['D&D 5e', 'Pathfinder'],
      totalXp: 200,
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    final testFriend2 = FriendEntity(
      id: 'friend2',
      displayName: 'Friend Two',
      email: 'friend2@test.com',
      bio: 'Second friend bio',
      experienceLevel: 'Intermediate',
      preferredSystems: ['Call of Cthulhu'],
      totalXp: 75,
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    );

    final testNotification1 = NotificationEntity(
      id: 'notif1',
      userId: '1',
      senderId: 'friend1',
      type: NotificationType.friendRequest,
      title: 'Friend Request',
      message: 'Friend One wants to be your friend',
      data: {'senderId': 'friend1'},
      isRead: false,
      isActioned: false,
      createdAt: DateTime.now(),
    );

    final testNotification2 = NotificationEntity(
      id: 'notif2',
      userId: '1',
      senderId: 'fellowship_creator',
      type: NotificationType.fellowshipInvite,
      title: 'Fellowship Invitation',
      message: 'You have been invited to join Adventure Guild',
      data: {'fellowshipId': 'fellowship1'},
      isRead: true,
      isActioned: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

    setUp(() {
      mockGetFriendsUseCase = MockGetFriendsUseCase();
      mockNotificationsRepository = MockNotificationsRepository();

      friendsBloc = FriendsBloc(
        getFriendsUseCase: mockGetFriendsUseCase,
        addFriendUseCase: MockAddFriendUseCase(),
        removeFriendUseCase: MockRemoveFriendUseCase(),
      );
      notificationsBloc = NotificationsBloc(
        repository: mockNotificationsRepository,
        indicatorService: MockNotificationIndicatorService(),
      );

      // Setup default mock responses
      when(
        () => mockNotificationsRepository.getUnreadCount(),
      ).thenAnswer((_) async => 1);
      when(
        () => mockNotificationsRepository.watchNotifications(),
      ).thenAnswer((_) => Stream.value([]));
    });

    tearDown(() {
      friendsBloc.close();
      notificationsBloc.close();
    });

    group('Friend Entity Tests', () {
      test('should create friend entity with correct properties', () {
        expect(testFriend1.id, equals('friend1'));
        expect(testFriend1.displayName, equals('Friend One'));
        expect(testFriend1.email, equals('friend1@test.com'));
        expect(testFriend1.bio, equals('First friend bio'));
        expect(testFriend1.experienceLevel, equals('Expert'));
        expect(testFriend1.preferredSystems, contains('D&D 5e'));
        expect(testFriend1.preferredSystems, contains('Pathfinder'));
        expect(testFriend1.totalXp, equals(200));
        expect(testFriend1.isOnline, isTrue);
        expect(testFriend1.lastSeen, isA<DateTime>());
      });

      test('should handle offline friend correctly', () {
        expect(testFriend2.isOnline, isFalse);
        expect(testFriend2.lastSeen, isA<DateTime>());
        expect(testFriend2.preferredSystems, contains('Call of Cthulhu'));
      });

      test('should support copyWith functionality', () {
        final updatedFriend = testFriend1.copyWith(
          isOnline: false,
          bio: 'Updated bio',
        );

        expect(updatedFriend.id, equals(testFriend1.id));
        expect(updatedFriend.displayName, equals(testFriend1.displayName));
        expect(updatedFriend.isOnline, isFalse);
        expect(updatedFriend.bio, equals('Updated bio'));
      });
    });

    group('Friends BLoC Tests', () {
      test('initial state should be FriendsInitial', () {
        expect(friendsBloc.state, equals(FriendsInitial()));
      });

      blocTest<FriendsBloc, FriendsState>(
        'should emit [FriendsLoading, FriendsLoaded] when LoadFriends is successful',
        build: () {
          when(
            () => mockGetFriendsUseCase(),
          ).thenAnswer((_) async => [testFriend1, testFriend2]);
          return friendsBloc;
        },
        act: (bloc) => bloc.add(const LoadFriends()),
        expect: () => [
          FriendsLoading(),
          FriendsLoaded([testFriend1, testFriend2]),
        ],
      );

      blocTest<FriendsBloc, FriendsState>(
        'should emit [FriendsLoading, FriendsError] when LoadFriends fails',
        build: () {
          when(
            () => mockGetFriendsUseCase(),
          ).thenThrow(Exception('Failed to load friends'));
          return friendsBloc;
        },
        act: (bloc) => bloc.add(const LoadFriends()),
        expect: () => [
          FriendsLoading(),
          FriendsError(
            'Failed to load friends: Exception: Failed to load friends',
          ),
        ],
      );

      blocTest<FriendsBloc, FriendsState>(
        'should emit [FriendsLoading, FriendsEmpty] with empty list when no friends',
        build: () {
          when(() => mockGetFriendsUseCase()).thenAnswer((_) async => []);
          return friendsBloc;
        },
        act: (bloc) => bloc.add(const LoadFriends()),
        expect: () => [FriendsLoading(), FriendsEmpty()],
      );
    });

    group('Notification Entity Tests', () {
      test('should create notification entity with correct properties', () {
        expect(testNotification1.id, equals('notif1'));
        expect(testNotification1.userId, equals('1'));
        expect(testNotification1.senderId, equals('friend1'));
        expect(testNotification1.type, equals(NotificationType.friendRequest));
        expect(testNotification1.title, equals('Friend Request'));
        expect(
          testNotification1.message,
          equals('Friend One wants to be your friend'),
        );
        expect(testNotification1.data, contains('senderId'));
        expect(testNotification1.isRead, isFalse);
        expect(testNotification1.createdAt, isA<DateTime>());
      });

      test('should handle different notification types correctly', () {
        expect(
          testNotification2.type,
          equals(NotificationType.fellowshipInvite),
        );
        expect(testNotification2.isRead, isTrue);
        expect(testNotification2.data, contains('fellowshipId'));
      });

      test('should have correct display properties', () {
        expect(
          NotificationType.friendRequest.displayName,
          equals('Friend Request'),
        );
        expect(
          NotificationType.fellowshipInvite.displayName,
          equals('Fellowship Invitation'),
        );
        expect(NotificationType.friendRequest.icon, equals('👋'));
        expect(NotificationType.fellowshipInvite.icon, equals('⚔️'));
      });

      test('should support copyWith functionality', () {
        final updatedNotification = testNotification1.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );

        expect(updatedNotification.id, equals(testNotification1.id));
        expect(updatedNotification.isRead, isTrue);
        expect(updatedNotification.readAt, isA<DateTime>());
        expect(updatedNotification.title, equals(testNotification1.title));
      });
    });

    group('Notifications BLoC Tests', () {
      test('initial state should be NotificationsInitial', () {
        expect(notificationsBloc.state, equals(const NotificationsInitial()));
      });

      blocTest<NotificationsBloc, NotificationsState>(
        'should emit [NotificationsLoading, NotificationsLoaded] when LoadNotifications is successful',
        build: () {
          when(
            () => mockNotificationsRepository.getNotifications(),
          ).thenAnswer((_) async => [testNotification1, testNotification2]);
          when(
            () => mockNotificationsRepository.getUnreadCount(),
          ).thenAnswer((_) async => 1);
          return notificationsBloc;
        },
        act: (bloc) => bloc.add(const LoadNotifications()),
        expect: () => [
          const NotificationsLoading(),
          NotificationsLoaded(
            notifications: [testNotification1, testNotification2],
            unreadCount: 1,
          ),
        ],
      );

      blocTest<NotificationsBloc, NotificationsState>(
        'should emit [NotificationsLoading, NotificationsError] when LoadNotifications fails',
        build: () {
          when(
            () => mockNotificationsRepository.getNotifications(),
          ).thenThrow(Exception('Failed to load notifications'));
          return notificationsBloc;
        },
        act: (bloc) => bloc.add(const LoadNotifications()),
        expect: () => [
          const NotificationsLoading(),
          const NotificationsError(
            'Failed to load notifications: Exception: Failed to load notifications',
          ),
        ],
      );

      blocTest<NotificationsBloc, NotificationsState>(
        'should emit [NotificationsLoading, NotificationsEmpty] when no notifications',
        build: () {
          when(
            () => mockNotificationsRepository.getNotifications(),
          ).thenAnswer((_) async => []);
          when(
            () => mockNotificationsRepository.getUnreadCount(),
          ).thenAnswer((_) async => 0);
          return notificationsBloc;
        },
        act: (bloc) => bloc.add(const LoadNotifications()),
        expect: () => [
          const NotificationsLoading(),
          const NotificationsEmpty(),
        ],
      );

      blocTest<NotificationsBloc, NotificationsState>(
        'should handle AcceptFriendRequest correctly',
        build: () {
          when(
            () => mockNotificationsRepository.acceptFriendRequest(
              'notif1',
              'friend1',
            ),
          ).thenAnswer((_) async {});
          when(
            () => mockNotificationsRepository.getNotifications(),
          ).thenAnswer((_) async => []);
          when(
            () => mockNotificationsRepository.getUnreadCount(),
          ).thenAnswer((_) async => 0);
          return notificationsBloc;
        },
        act: (bloc) => bloc.add(
          const AcceptFriendRequest(
            notificationId: 'notif1',
            senderId: 'friend1',
          ),
        ),
        expect: () => [
          const NotificationActionInProgress(
            notificationId: 'notif1',
            action: 'accepting',
          ),
          const FriendRequestAccepted('friend1'),
          const NotificationActionSuccess('Friend request accepted!'),
          const NotificationsLoading(),
          const NotificationsEmpty(),
        ],
      );

      blocTest<NotificationsBloc, NotificationsState>(
        'should handle DeclineFriendRequest correctly',
        build: () {
          when(
            () => mockNotificationsRepository.declineFriendRequest(
              'notif1',
              'friend1',
            ),
          ).thenAnswer((_) async {});
          when(
            () => mockNotificationsRepository.getNotifications(),
          ).thenAnswer((_) async => []);
          when(
            () => mockNotificationsRepository.getUnreadCount(),
          ).thenAnswer((_) async => 0);
          return notificationsBloc;
        },
        act: (bloc) => bloc.add(
          const DeclineFriendRequest(
            notificationId: 'notif1',
            senderId: 'friend1',
          ),
        ),
        expect: () => [
          const NotificationActionInProgress(
            notificationId: 'notif1',
            action: 'declining',
          ),
          const NotificationActionSuccess('Friend request declined'),
          const NotificationsLoading(),
          const NotificationsEmpty(),
        ],
      );

      blocTest<NotificationsBloc, NotificationsState>(
        'should handle MarkAsRead correctly',
        build: () {
          when(
            () => mockNotificationsRepository.markAsRead('notif1'),
          ).thenAnswer((_) async {});
          when(
            () => mockNotificationsRepository.getNotifications(),
          ).thenAnswer((_) async => []);
          when(
            () => mockNotificationsRepository.getUnreadCount(),
          ).thenAnswer((_) async => 0);
          return notificationsBloc;
        },
        act: (bloc) => bloc.add(const MarkAsRead('notif1')),
        expect: () => [
          const NotificationsLoading(),
          const NotificationsEmpty(),
        ],
      );

      blocTest<NotificationsBloc, NotificationsState>(
        'should handle MarkAllAsRead correctly',
        build: () {
          when(
            () => mockNotificationsRepository.markAllAsRead(),
          ).thenAnswer((_) async {});
          when(
            () => mockNotificationsRepository.getNotifications(),
          ).thenAnswer((_) async => []);
          when(
            () => mockNotificationsRepository.getUnreadCount(),
          ).thenAnswer((_) async => 0);
          return notificationsBloc;
        },
        act: (bloc) => bloc.add(const MarkAllAsRead()),
        expect: () => [
          const NotificationActionSuccess('All notifications marked as read'),
          const NotificationsLoading(),
          const NotificationsEmpty(),
        ],
      );

      blocTest<NotificationsBloc, NotificationsState>(
        'should handle DeleteNotification correctly',
        build: () {
          when(
            () => mockNotificationsRepository.deleteNotification('notif1'),
          ).thenAnswer((_) async {});
          when(
            () => mockNotificationsRepository.getNotifications(),
          ).thenAnswer((_) async => []);
          when(
            () => mockNotificationsRepository.getUnreadCount(),
          ).thenAnswer((_) async => 0);
          return notificationsBloc;
        },
        act: (bloc) => bloc.add(const DeleteNotification('notif1')),
        expect: () => [
          const NotificationActionSuccess('Notification deleted'),
          const NotificationsLoading(),
          const NotificationsEmpty(),
        ],
      );
    });

    group('Notification Type Extension Tests', () {
      test(
        'should provide correct display names for all notification types',
        () {
          expect(
            NotificationType.friendRequest.displayName,
            equals('Friend Request'),
          );
          expect(
            NotificationType.friendRequestAccepted.displayName,
            equals('Friend Request Accepted'),
          );
          expect(
            NotificationType.fellowshipInvite.displayName,
            equals('Fellowship Invitation'),
          );
          expect(
            NotificationType.fellowshipJoined.displayName,
            equals('Fellowship Joined'),
          );
          expect(
            NotificationType.fellowshipMessage.displayName,
            equals('Fellowship Message'),
          );
          expect(
            NotificationType.directMessage.displayName,
            equals('Direct Message'),
          );
          expect(
            NotificationType.fellowshipCreated.displayName,
            equals('Fellowship Created'),
          );
          expect(
            NotificationType.systemMessage.displayName,
            equals('System Message'),
          );
        },
      );

      test('should provide correct icons for all notification types', () {
        expect(NotificationType.friendRequest.icon, equals('👋'));
        expect(NotificationType.friendRequestAccepted.icon, equals('✅'));
        expect(NotificationType.fellowshipInvite.icon, equals('⚔️'));
        expect(NotificationType.fellowshipJoined.icon, equals('🎉'));
        expect(NotificationType.fellowshipMessage.icon, equals('💬'));
        expect(NotificationType.directMessage.icon, equals('📱'));
        expect(NotificationType.fellowshipCreated.icon, equals('🏰'));
        expect(NotificationType.systemMessage.icon, equals('🔔'));
      });
    });

    group('Error Handling Tests', () {
      blocTest<FriendsBloc, FriendsState>(
        'should handle network errors gracefully',
        build: () {
          when(
            () => mockGetFriendsUseCase(),
          ).thenThrow(Exception('Network connection failed'));
          return friendsBloc;
        },
        act: (bloc) => bloc.add(const LoadFriends()),
        expect: () => [
          FriendsLoading(),
          FriendsError(
            'Failed to load friends: Exception: Network connection failed',
          ),
        ],
      );

      blocTest<NotificationsBloc, NotificationsState>(
        'should handle repository errors gracefully',
        build: () {
          when(
            () => mockNotificationsRepository.getNotifications(),
          ).thenThrow(Exception('Database error'));
          return notificationsBloc;
        },
        act: (bloc) => bloc.add(const LoadNotifications()),
        expect: () => [
          const NotificationsLoading(),
          const NotificationsError(
            'Failed to load notifications: Exception: Database error',
          ),
        ],
      );

      blocTest<NotificationsBloc, NotificationsState>(
        'should handle friend request acceptance errors',
        build: () {
          when(
            () => mockNotificationsRepository.acceptFriendRequest(
              'notif1',
              'friend1',
            ),
          ).thenThrow(Exception('Friend request failed'));
          return notificationsBloc;
        },
        act: (bloc) => bloc.add(
          const AcceptFriendRequest(
            notificationId: 'notif1',
            senderId: 'friend1',
          ),
        ),
        expect: () => [
          const NotificationActionInProgress(
            notificationId: 'notif1',
            action: 'accepting',
          ),
          const NotificationsError(
            'Failed to accept friend request: Exception: Friend request failed',
          ),
        ],
      );
    });

    group('Integration Tests', () {
      test('friends and notifications work together', () {
        // Test that friend entities can be used in notification data
        final friendRequestNotification = NotificationEntity(
          id: 'test_notif',
          userId: 'current_user',
          senderId: testFriend1.id,
          type: NotificationType.friendRequest,
          title: 'Friend Request',
          message: '${testFriend1.displayName} wants to be your friend',
          data: {
            'senderId': testFriend1.id,
            'senderName': testFriend1.displayName,
            'senderEmail': testFriend1.email,
          },
          isRead: false,
          isActioned: false,
          createdAt: DateTime.now(),
        );

        expect(
          friendRequestNotification.data!['senderId'],
          equals(testFriend1.id),
        );
        expect(
          friendRequestNotification.data!['senderName'],
          equals(testFriend1.displayName),
        );
        expect(
          friendRequestNotification.message,
          contains(testFriend1.displayName),
        );
      });

      test('notification types support all expected scenarios', () {
        final allTypes = NotificationType.values;

        // Ensure we have all expected notification types
        expect(allTypes, contains(NotificationType.friendRequest));
        expect(allTypes, contains(NotificationType.friendRequestAccepted));
        expect(allTypes, contains(NotificationType.fellowshipInvite));
        expect(allTypes, contains(NotificationType.fellowshipJoined));
        expect(allTypes, contains(NotificationType.fellowshipMessage));
        expect(allTypes, contains(NotificationType.directMessage));
        expect(allTypes, contains(NotificationType.fellowshipCreated));
        expect(allTypes, contains(NotificationType.systemMessage));

        // Ensure all types have display names and icons
        for (final type in allTypes) {
          expect(type.displayName, isNotEmpty);
          expect(type.icon, isNotEmpty);
        }
      });
    });
  });
}
