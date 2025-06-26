import 'package:equatable/equatable.dart';

class FriendEntity extends Equatable {
  const FriendEntity({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.bio,
    this.isOnline = false,
    this.lastSeen,
    this.preferredSystems = const [],
    this.experienceLevel,
    this.totalXp = 0,
  });

  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? bio;
  final bool isOnline;
  final DateTime? lastSeen;
  final List<String> preferredSystems;
  final String? experienceLevel;
  final int totalXp;

  @override
  List<Object?> get props => [
    id,
    displayName,
    email,
    photoUrl,
    bio,
    isOnline,
    lastSeen,
    preferredSystems,
    experienceLevel,
    totalXp,
  ];

  FriendEntity copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
    List<String>? preferredSystems,
    String? experienceLevel,
    int? totalXp,
  }) {
    return FriendEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      preferredSystems: preferredSystems ?? this.preferredSystems,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      totalXp: totalXp ?? this.totalXp,
    );
  }
}
