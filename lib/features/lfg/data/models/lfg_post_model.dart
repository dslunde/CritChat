import 'package:critchat/features/lfg/domain/entities/lfg_post_entity.dart';

class LfgPostModel extends LfgPostEntity {
  const LfgPostModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userLevel,
    required super.gameSystem,
    required super.playStyles,
    required super.sessionFormat,
    required super.schedulePreference,
    required super.campaignLength,
    required super.callToAdventureText,
    required super.createdAt,
    super.lastRefreshed,
    required super.isClosed,
    required super.interestedUserIds,
    super.matchScore,
  });

  factory LfgPostModel.fromEntity(LfgPostEntity entity) {
    return LfgPostModel(
      id: entity.id,
      userId: entity.userId,
      userName: entity.userName,
      userLevel: entity.userLevel,
      gameSystem: entity.gameSystem,
      playStyles: entity.playStyles,
      sessionFormat: entity.sessionFormat,
      schedulePreference: entity.schedulePreference,
      campaignLength: entity.campaignLength,
      callToAdventureText: entity.callToAdventureText,
      createdAt: entity.createdAt,
      lastRefreshed: entity.lastRefreshed,
      isClosed: entity.isClosed,
      interestedUserIds: entity.interestedUserIds,
      matchScore: entity.matchScore,
    );
  }

  factory LfgPostModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return LfgPostModel(
      id: docId ?? json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userLevel: json['userLevel'] as int,
      gameSystem: json['gameSystem'] as String,
      playStyles: List<String>.from(json['playStyles'] as List),
      sessionFormat: json['sessionFormat'] as String,
      schedulePreference: json['schedulePreference'] as String,
      campaignLength: json['campaignLength'] as String,
      callToAdventureText: json['callToAdventureText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastRefreshed: json['lastRefreshed'] != null 
          ? DateTime.parse(json['lastRefreshed'] as String)
          : null,
      isClosed: json['isClosed'] as bool,
      interestedUserIds: List<String>.from(json['interestedUserIds'] as List),
      matchScore: json['matchScore'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userLevel': userLevel,
      'gameSystem': gameSystem,
      'playStyles': playStyles,
      'sessionFormat': sessionFormat,
      'schedulePreference': schedulePreference,
      'campaignLength': campaignLength,
      'callToAdventureText': callToAdventureText,
      'createdAt': createdAt.toIso8601String(),
      'lastRefreshed': lastRefreshed?.toIso8601String(),
      'isClosed': isClosed,
      'interestedUserIds': interestedUserIds,
      'matchScore': matchScore,
    };
  }

  @override
  LfgPostModel copyWith({
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
    return LfgPostModel(
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
} 