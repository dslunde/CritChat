import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:critchat/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationIndicatorService {
  final NotificationsRepository _notificationsRepository;

  // Stream controllers for different types of unread indicators
  final StreamController<int> _unreadNotificationsController =
      StreamController<int>.broadcast();
  final StreamController<int> _unreadFriendMessagesController =
      StreamController<int>.broadcast();
  final StreamController<int> _unreadFellowshipMessagesController =
      StreamController<int>.broadcast();
  final StreamController<Map<String, int>> _unreadFriendMessagesMapController =
      StreamController<Map<String, int>>.broadcast();
  final StreamController<Map<String, int>>
  _unreadFellowshipMessagesMapController =
      StreamController<Map<String, int>>.broadcast();
  final StreamController<int> _unreadForMeController =
      StreamController<int>.broadcast();
  final StreamController<int> _unreadLfgController =
      StreamController<int>.broadcast();

  // Current counts
  int _unreadNotifications = 0;
  int _unreadFriendMessages = 0;
  int _unreadFellowshipMessages = 0;
  Map<String, int> _unreadFriendMessagesMap = {};
  Map<String, int> _unreadFellowshipMessagesMap = {};
  int _unreadForMe = 0;
  int _unreadLfg = 0;

  NotificationIndicatorService({
    required NotificationsRepository notificationsRepository,
  }) : _notificationsRepository = notificationsRepository;

  // Getters for streams
  Stream<int> get unreadNotificationsStream =>
      _unreadNotificationsController.stream;
  Stream<int> get unreadFriendMessagesStream =>
      _unreadFriendMessagesController.stream;
  Stream<int> get unreadFellowshipMessagesStream =>
      _unreadFellowshipMessagesController.stream;
  Stream<Map<String, int>> get unreadFriendMessagesMapStream =>
      _unreadFriendMessagesMapController.stream;
  Stream<Map<String, int>> get unreadFellowshipMessagesMapStream =>
      _unreadFellowshipMessagesMapController.stream;
  Stream<int> get unreadForMeStream => _unreadForMeController.stream;
  Stream<int> get unreadLfgStream => _unreadLfgController.stream;

  // Getters for current counts
  int get unreadNotifications => _unreadNotifications;
  int get unreadFriendMessages => _unreadFriendMessages;
  int get unreadFellowshipMessages => _unreadFellowshipMessages;
  Map<String, int> get unreadFriendMessagesMap => _unreadFriendMessagesMap;
  Map<String, int> get unreadFellowshipMessagesMap =>
      _unreadFellowshipMessagesMap;
  int get unreadForMe => _unreadForMe;
  int get unreadLfg => _unreadLfg;

  // Methods to update counts
  void updateUnreadNotifications(int count) {
    if (_unreadNotifications != count) {
      _unreadNotifications = count;
      _unreadNotificationsController.add(count);
    }
  }

  void updateUnreadFriendMessages(int count) {
    if (_unreadFriendMessages != count) {
      _unreadFriendMessages = count;
      _unreadFriendMessagesController.add(count);
    }
  }

  void updateUnreadFellowshipMessages(int count) {
    if (_unreadFellowshipMessages != count) {
      _unreadFellowshipMessages = count;
      _unreadFellowshipMessagesController.add(count);
    }
  }

  void updateUnreadFriendMessagesMap(Map<String, int> map) {
    if (!_mapsEqual(_unreadFriendMessagesMap, map)) {
      _unreadFriendMessagesMap = Map.from(map);
      _unreadFriendMessagesMapController.add(_unreadFriendMessagesMap);
    }
  }

  void updateUnreadFellowshipMessagesMap(Map<String, int> map) {
    if (!_mapsEqual(_unreadFellowshipMessagesMap, map)) {
      _unreadFellowshipMessagesMap = Map.from(map);
      _unreadFellowshipMessagesMapController.add(_unreadFellowshipMessagesMap);
    }
  }

  void updateUnreadForMe(int count) {
    if (_unreadForMe != count) {
      _unreadForMe = count;
      _unreadForMeController.add(count);
    }
  }

  void updateUnreadLfg(int count) {
    if (_unreadLfg != count) {
      _unreadLfg = count;
      _unreadLfgController.add(count);
    }
  }

  // Helper method to compare maps
  bool _mapsEqual(Map<String, int> map1, Map<String, int> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  // Mark specific friend messages as read
  void markFriendMessagesAsRead(String friendId) {
    if (_unreadFriendMessagesMap.containsKey(friendId)) {
      final newMap = Map<String, int>.from(_unreadFriendMessagesMap);
      newMap.remove(friendId);
      updateUnreadFriendMessagesMap(newMap);

      // Update total count
      final totalCount = newMap.values.fold(0, (sum, count) => sum + count);
      updateUnreadFriendMessages(totalCount);
    }
  }

  // Mark specific fellowship messages as read
  void markFellowshipMessagesAsRead(String fellowshipId) {
    if (_unreadFellowshipMessagesMap.containsKey(fellowshipId)) {
      final newMap = Map<String, int>.from(_unreadFellowshipMessagesMap);
      newMap.remove(fellowshipId);
      updateUnreadFellowshipMessagesMap(newMap);

      // Update total count
      final totalCount = newMap.values.fold(0, (sum, count) => sum + count);
      updateUnreadFellowshipMessages(totalCount);
    }
  }

  // Initialize the service by loading current counts
  Future<void> initialize() async {
    try {
      // Load unread notifications count
      final notificationCount = await _notificationsRepository.getUnreadCount();
      updateUnreadNotifications(notificationCount);

      // TODO: Load other counts when chat read tracking is implemented
      // For now, set placeholder values
      updateUnreadFriendMessages(0);
      updateUnreadFellowshipMessages(0);
      updateUnreadFriendMessagesMap({});
      updateUnreadFellowshipMessagesMap({});
      updateUnreadForMe(0);
      updateUnreadLfg(0);
    } catch (e) {
      debugPrint('Error initializing notification indicator service: $e');
    }
  }

  void dispose() {
    _unreadNotificationsController.close();
    _unreadFriendMessagesController.close();
    _unreadFellowshipMessagesController.close();
    _unreadFriendMessagesMapController.close();
    _unreadFellowshipMessagesMapController.close();
    _unreadForMeController.close();
    _unreadLfgController.close();
  }
}
