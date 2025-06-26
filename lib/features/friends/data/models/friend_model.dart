import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/friend_entity.dart';
import '../../../auth/data/models/user_model.dart';

class FriendModel extends FriendEntity {
  const FriendModel({
    required super.id,
    required super.displayName,
    required super.email,
    super.photoUrl,
    super.bio,
    super.isOnline,
    super.lastSeen,
    super.preferredSystems,
    super.experienceLevel,
    super.totalXp,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Timestamp).toDate()
          : null,
      preferredSystems: List<String>.from(json['preferredSystems'] ?? []),
      experienceLevel: json['experienceLevel'] as String?,
      totalXp: json['totalXp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'preferredSystems': preferredSystems,
      'experienceLevel': experienceLevel,
      'totalXp': totalXp,
    };
  }

  factory FriendModel.fromEntity(FriendEntity entity) {
    return FriendModel(
      id: entity.id,
      displayName: entity.displayName,
      email: entity.email,
      photoUrl: entity.photoUrl,
      bio: entity.bio,
      isOnline: entity.isOnline,
      lastSeen: entity.lastSeen,
      preferredSystems: entity.preferredSystems,
      experienceLevel: entity.experienceLevel,
      totalXp: entity.totalXp,
    );
  }

  factory FriendModel.fromUserModel(UserModel user) {
    return FriendModel(
      id: user.id,
      displayName: user.displayName ?? 'Unknown User',
      email: user.email,
      photoUrl: user.photoUrl,
      bio: user.bio,
      isOnline: false, // This would be calculated from presence system
      lastSeen: user.lastLogin,
      preferredSystems: user.preferredSystems,
      experienceLevel: user.experienceLevel,
      totalXp: user.totalXp,
    );
  }
}
