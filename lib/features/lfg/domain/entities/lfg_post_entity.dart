import 'package:equatable/equatable.dart';

class LfgPostEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final int userLevel;
  final String gameSystem;
  final List<String> playStyles;
  final String sessionFormat;
  final String schedulePreference;
  final String campaignLength;
  final String callToAdventureText;
  final DateTime createdAt;
  final DateTime? lastRefreshed;
  final bool isClosed;
  final List<String> interestedUserIds;
  final double? matchScore; // For display purposes

  const LfgPostEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userLevel,
    required this.gameSystem,
    required this.playStyles,
    required this.sessionFormat,
    required this.schedulePreference,
    required this.campaignLength,
    required this.callToAdventureText,
    required this.createdAt,
    this.lastRefreshed,
    required this.isClosed,
    required this.interestedUserIds,
    this.matchScore,
  });

  bool isOwner(String userId) => this.userId == userId;

  bool hasUserExpressedInterest(String userId) => interestedUserIds.contains(userId);

  int get interestCount => interestedUserIds.length;

  bool get isExpired {
    // Posts are considered for expiry notification after 1 month
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    final referenceDate = lastRefreshed ?? createdAt;
    return referenceDate.isBefore(oneMonthAgo);
  }

  bool get shouldBeDeleted {
    // Closed posts should be deleted after 1 week
    if (!isClosed) return false;
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    return createdAt.isBefore(oneWeekAgo);
  }

  LfgPostEntity copyWith({
    String? id,
    String? userId,
    String? userName,
    int? userLevel,
    String? gameSystem,
    List<String>? playStyles,
    String? sessionFormat,
    String? schedulePreference,
    String? campaignLength,
    String? callToAdventureText,
    DateTime? createdAt,
    DateTime? lastRefreshed,
    bool? isClosed,
    List<String>? interestedUserIds,
    double? matchScore,
  }) {
    return LfgPostEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userLevel: userLevel ?? this.userLevel,
      gameSystem: gameSystem ?? this.gameSystem,
      playStyles: playStyles ?? this.playStyles,
      sessionFormat: sessionFormat ?? this.sessionFormat,
      schedulePreference: schedulePreference ?? this.schedulePreference,
      campaignLength: campaignLength ?? this.campaignLength,
      callToAdventureText: callToAdventureText ?? this.callToAdventureText,
      createdAt: createdAt ?? this.createdAt,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      isClosed: isClosed ?? this.isClosed,
      interestedUserIds: interestedUserIds ?? this.interestedUserIds,
      matchScore: matchScore ?? this.matchScore,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    userLevel,
    gameSystem,
    playStyles,
    sessionFormat,
    schedulePreference,
    campaignLength,
    callToAdventureText,
    createdAt,
    lastRefreshed,
    isClosed,
    interestedUserIds,
    matchScore,
  ];

  @override
  String toString() =>
      'LfgPostEntity('
      'id: $id, '
      'userId: $userId, '
      'userName: $userName, '
      'userLevel: $userLevel, '
      'gameSystem: $gameSystem, '
      'playStyles: $playStyles, '
      'sessionFormat: $sessionFormat, '
      'schedulePreference: $schedulePreference, '
      'campaignLength: $campaignLength, '
      'callToAdventureText: $callToAdventureText, '
      'createdAt: $createdAt, '
      'lastRefreshed: $lastRefreshed, '
      'isClosed: $isClosed, '
      'interestedUserIds: $interestedUserIds, '
      'matchScore: $matchScore'
      ')';
} 