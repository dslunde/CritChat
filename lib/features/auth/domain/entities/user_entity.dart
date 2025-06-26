import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.preferredSystems = const [],
    this.experienceLevel,
    this.totalXp = 0,
    this.friends = const [],
    this.fellowships = const [],
    this.joinedGroups =
        const [], // Deprecated - keeping for backward compatibility
    this.createdAt,
    this.lastLogin,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? bio;
  final List<String> preferredSystems;
  final String?
  experienceLevel; // 'beginner', 'intermediate', 'experienced', 'veteran'
  final int totalXp;
  final List<String> friends; // List of user IDs
  final List<String> fellowships; // List of fellowship IDs
  final List<String>
  joinedGroups; // Deprecated - keeping for backward compatibility
  final DateTime? createdAt;
  final DateTime? lastLogin;

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    bio,
    preferredSystems,
    experienceLevel,
    totalXp,
    friends,
    fellowships,
    joinedGroups,
    createdAt,
    lastLogin,
  ];

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? preferredSystems,
    String? experienceLevel,
    int? totalXp,
    List<String>? friends,
    List<String>? fellowships,
    List<String>? joinedGroups,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      preferredSystems: preferredSystems ?? this.preferredSystems,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      totalXp: totalXp ?? this.totalXp,
      friends: friends ?? this.friends,
      fellowships: fellowships ?? this.fellowships,
      joinedGroups: joinedGroups ?? this.joinedGroups,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
