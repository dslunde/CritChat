import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:critchat/features/gamification/domain/entities/xp_entity.dart';

/// Firestore model for user XP data
class XpModel extends XpEntity {
  const XpModel({
    required super.userId,
    required super.totalXp,
    required super.currentLevel,
    required super.xpForCurrentLevel,
    required super.xpForNextLevel,
    required super.lastUpdated,
  });

  /// Create XpModel from XpEntity
  factory XpModel.fromEntity(XpEntity entity) {
    return XpModel(
      userId: entity.userId,
      totalXp: entity.totalXp,
      currentLevel: entity.currentLevel,
      xpForCurrentLevel: entity.xpForCurrentLevel,
      xpForNextLevel: entity.xpForNextLevel,
      lastUpdated: entity.lastUpdated,
    );
  }

  /// Create XpModel from Firestore document
  factory XpModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final totalXp = data['totalXp'] as int? ?? 0;
    final currentLevel = XpEntity.calculateLevelFromXp(totalXp);
    final xpForCurrentLevel = XpEntity.calculateXpForLevel(currentLevel);
    final xpForNextLevel = XpEntity.calculateXpForLevel(currentLevel + 1);

    return XpModel(
      userId: doc.id,
      totalXp: totalXp,
      currentLevel: currentLevel,
      xpForCurrentLevel: xpForCurrentLevel,
      xpForNextLevel: xpForNextLevel,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {'totalXp': totalXp, 'lastUpdated': Timestamp.fromDate(lastUpdated)};
  }

  /// Create initial XP model for new users
  factory XpModel.initial(String userId) {
    return XpModel(
      userId: userId,
      totalXp: 0,
      currentLevel: 1,
      xpForCurrentLevel: 0,
      xpForNextLevel: 100,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Firestore model for XP transaction data
class XpTransactionModel extends XpTransactionEntity {
  const XpTransactionModel({
    required super.id,
    required super.userId,
    required super.rewardType,
    required super.xpAwarded,
    required super.description,
    required super.timestamp,
    super.metadata,
  });

  /// Create XpTransactionModel from XpTransactionEntity
  factory XpTransactionModel.fromEntity(XpTransactionEntity entity) {
    return XpTransactionModel(
      id: entity.id,
      userId: entity.userId,
      rewardType: entity.rewardType,
      xpAwarded: entity.xpAwarded,
      description: entity.description,
      timestamp: entity.timestamp,
      metadata: entity.metadata,
    );
  }

  /// Create XpTransactionModel from Firestore document
  factory XpTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return XpTransactionModel(
      id: doc.id,
      userId: data['userId'] as String,
      rewardType: XpRewardType.values.firstWhere(
        (type) => type.name == data['rewardType'],
        orElse: () => XpRewardType.sendMessage,
      ),
      xpAwarded: data['xpAwarded'] as int,
      description: data['description'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'rewardType': rewardType.name,
      'xpAwarded': xpAwarded,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create new transaction model
  factory XpTransactionModel.create({
    required String userId,
    required XpRewardType rewardType,
    Map<String, dynamic>? metadata,
  }) {
    return XpTransactionModel(
      id: '', // Will be set by Firestore
      userId: userId,
      rewardType: rewardType,
      xpAwarded: rewardType.xpAmount,
      description: rewardType.description,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }
}
