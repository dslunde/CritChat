import 'package:critchat/features/lfg/domain/entities/lfg_post_entity.dart';

abstract class LfgRepository {
  Future<List<LfgPostEntity>> getActiveLfgPosts(String currentUserId);
  Future<List<LfgPostEntity>> getUserLfgPosts(String userId);
  Future<LfgPostEntity> createLfgPost(LfgPostEntity post);
  Future<LfgPostEntity> updateLfgPost(LfgPostEntity post);
  Future<bool> expressInterest(String postId, String userId);
  Future<bool> closeLfgPost(String postId);
  Future<LfgPostEntity> refreshLfgPost(String postId);
  Future<bool> deleteLfgPost(String postId);
  Stream<List<LfgPostEntity>> getLfgPostsStream();
  Future<int> getUserActivePostCount(String userId);
} 