import 'package:equatable/equatable.dart';

abstract class LfgEvent extends Equatable {
  const LfgEvent();

  @override
  List<Object?> get props => [];
}

class LoadLfgPosts extends LfgEvent {
  final String currentUserId;

  const LoadLfgPosts({required this.currentUserId});

  @override
  List<Object?> get props => [currentUserId];
}

class LoadUserLfgPosts extends LfgEvent {
  final String userId;

  const LoadUserLfgPosts({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class CreateLfgPost extends LfgEvent {
  final String userId;
  final String userName;
  final int userLevel;
  final String gameSystem;
  final List<String> playStyles;
  final String sessionFormat;
  final String schedulePreference;
  final String campaignLength;
  final String callToAdventureText;

  const CreateLfgPost({
    required this.userId,
    required this.userName,
    required this.userLevel,
    required this.gameSystem,
    required this.playStyles,
    required this.sessionFormat,
    required this.schedulePreference,
    required this.campaignLength,
    required this.callToAdventureText,
  });

  @override
  List<Object?> get props => [
    userId,
    userName,
    userLevel,
    gameSystem,
    playStyles,
    sessionFormat,
    schedulePreference,
    campaignLength,
    callToAdventureText,
  ];
}

class ExpressInterest extends LfgEvent {
  final String postId;
  final String userId;

  const ExpressInterest({
    required this.postId,
    required this.userId,
  });

  @override
  List<Object?> get props => [postId, userId];
}

class CloseLfgPost extends LfgEvent {
  final String postId;

  const CloseLfgPost({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class RefreshLfgPost extends LfgEvent {
  final String postId;

  const RefreshLfgPost({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class CreateFellowshipFromPost extends LfgEvent {
  final String postId;
  final String fellowshipName;
  final String fellowshipDescription;
  final bool isPublic;
  final String? joinCode;

  const CreateFellowshipFromPost({
    required this.postId,
    required this.fellowshipName,
    required this.fellowshipDescription,
    required this.isPublic,
    this.joinCode,
  });

  @override
  List<Object?> get props => [
    postId,
    fellowshipName,
    fellowshipDescription,
    isPublic,
    joinCode,
  ];
}

class DeleteLfgPost extends LfgEvent {
  final String postId;

  const DeleteLfgPost({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class RefreshLfgFeed extends LfgEvent {
  final String currentUserId;

  const RefreshLfgFeed({required this.currentUserId});

  @override
  List<Object?> get props => [currentUserId];
} 