import 'package:equatable/equatable.dart';
import 'package:critchat/features/lfg/domain/entities/lfg_post_entity.dart';
import 'package:critchat/features/fellowships/domain/entities/fellowship_entity.dart';

abstract class LfgState extends Equatable {
  const LfgState();

  @override
  List<Object?> get props => [];
}

class LfgInitial extends LfgState {}

class LfgLoading extends LfgState {}

class LfgPostsLoaded extends LfgState {
  final List<LfgPostEntity> posts;

  const LfgPostsLoaded(this.posts);

  @override
  List<Object?> get props => [posts];
}

class UserLfgPostsLoaded extends LfgState {
  final List<LfgPostEntity> userPosts;

  const UserLfgPostsLoaded(this.userPosts);

  @override
  List<Object?> get props => [userPosts];
}

class LfgPostCreated extends LfgState {
  final LfgPostEntity post;
  final String message;

  const LfgPostCreated({
    required this.post,
    this.message = 'LFG post created successfully!',
  });

  @override
  List<Object?> get props => [post, message];
}

class InterestExpressed extends LfgState {
  final String message;

  const InterestExpressed({
    this.message = 'Interest expressed successfully!',
  });

  @override
  List<Object?> get props => [message];
}

class LfgPostClosed extends LfgState {
  final String message;

  const LfgPostClosed({
    this.message = 'LFG post closed successfully!',
  });

  @override
  List<Object?> get props => [message];
}

class LfgPostRefreshed extends LfgState {
  final LfgPostEntity post;
  final String message;

  const LfgPostRefreshed({
    required this.post,
    this.message = 'LFG post refreshed successfully!',
  });

  @override
  List<Object?> get props => [post, message];
}

class FellowshipCreatedFromPost extends LfgState {
  final FellowshipEntity fellowship;
  final String message;

  const FellowshipCreatedFromPost({
    required this.fellowship,
    this.message = 'Fellowship created successfully! Invites sent to interested players.',
  });

  @override
  List<Object?> get props => [fellowship, message];
}

class LfgPostDeleted extends LfgState {
  final String message;

  const LfgPostDeleted({
    this.message = 'LFG post deleted successfully!',
  });

  @override
  List<Object?> get props => [message];
}

class LfgError extends LfgState {
  final String message;

  const LfgError(this.message);

  @override
  List<Object?> get props => [message];
}

class LfgOperationSuccess extends LfgState {
  final String message;

  const LfgOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
} 