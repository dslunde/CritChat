import 'package:critchat/features/lfg/data/models/lfg_post_model.dart';

class LfgMockDataSource {
  final List<LfgPostModel> _posts = [
    LfgPostModel(
      id: 'lfg1',
      userId: '1',
      userName: 'Alex the Adventurer',
      userLevel: 750,
      gameSystem: 'D&D 5e',
      playStyles: ['Roleplay-Focused', 'Exploration'],
      sessionFormat: 'Online (Video/Voice)',
      schedulePreference: '1/week',
      campaignLength: 'Long Campaign',
      callToAdventureText: 'Seeking fellow adventurers for an epic journey through the Forgotten Realms! Looking for players who love deep character development and collaborative storytelling. New players welcome - I love helping people learn the game!',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isClosed: false,
      interestedUserIds: ['2', '3'],
    ),
    LfgPostModel(
      id: 'lfg2',
      userId: '4',
      userName: 'Morgan Blackwood',
      userLevel: 1200,
      gameSystem: 'Call of Cthulhu',
      playStyles: ['Political Intrigue', 'Puzzle-Solving'],
      sessionFormat: 'Semi-Asynchronous (through CritChat)',
      schedulePreference: '2/month',
      campaignLength: 'Short Campaign',
      callToAdventureText: 'The shadows of Arkham hide terrible secrets... Join me for a 1920s mystery campaign where sanity is optional but great roleplay is essential. Perfect for busy schedules with async play between sessions.',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      isClosed: false,
      interestedUserIds: ['5'],
    ),
    LfgPostModel(
      id: 'lfg3',
      userId: '6',
      userName: 'Commander Steel',
      userLevel: 2100,
      gameSystem: 'Pathfinder 2e',
      playStyles: ['Combat-Heavy', 'Tactical'],
      sessionFormat: 'In-Person',
      schedulePreference: '2/week',
      campaignLength: 'One-Shot',
      callToAdventureText: 'High-level tactical combat one-shot this weekend! Bring your best builds and strategic thinking. We\'ll be facing ancient dragons and testing the limits of Pathfinder\'s combat system. Veterans preferred.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isClosed: false,
      interestedUserIds: ['7', '8', '9'],
    ),
    LfgPostModel(
      id: 'lfg4',
      userId: '10',
      userName: 'Luna Stormwright',
      userLevel: 450,
      gameSystem: 'Cosmere RPG',
      playStyles: ['Exploration', 'Magic-Heavy'],
      sessionFormat: 'Hybrid',
      schedulePreference: '1/month',
      campaignLength: 'Medium Campaign',
      callToAdventureText: 'The Shattered Plains await! Looking for Radiants and scholars to explore Brandon Sanderson\'s incredible world. New system, new adventures, and the chance to wield Shardblades! Sanderson fans especially welcome.',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      isClosed: false,
      interestedUserIds: [],
    ),
  ];

  Future<List<LfgPostModel>> getActiveLfgPosts() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _posts.where((post) => !post.isClosed).toList();
  }

  Future<List<LfgPostModel>> getUserLfgPosts(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _posts.where((post) => post.userId == userId).toList();
  }

  Future<LfgPostModel> createLfgPost(LfgPostModel post) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final newPost = post.copyWith(
      id: 'lfg_${DateTime.now().millisecondsSinceEpoch}',
    );

    _posts.add(newPost);
    return newPost;
  }

  Future<LfgPostModel> updateLfgPost(LfgPostModel post) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index >= 0) {
      _posts[index] = post;
      return post;
    } else {
      throw Exception('Post not found');
    }
  }

  Future<void> expressInterest(String postId, String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index >= 0) {
      final post = _posts[index];
      if (!post.interestedUserIds.contains(userId)) {
        _posts[index] = post.copyWith(
          interestedUserIds: [...post.interestedUserIds, userId],
        );
      }
    }
  }

  Future<void> closeLfgPost(String postId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index >= 0) {
      _posts[index] = _posts[index].copyWith(isClosed: true);
    }
  }

  Future<LfgPostModel> refreshLfgPost(String postId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index >= 0) {
      final refreshedPost = _posts[index].copyWith(
        lastRefreshed: DateTime.now(),
      );
      _posts[index] = refreshedPost;
      return refreshedPost;
    } else {
      throw Exception('Post not found');
    }
  }

  Future<void> deleteLfgPost(String postId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    _posts.removeWhere((p) => p.id == postId);
  }

  Stream<List<LfgPostModel>> getLfgPostsStream() async* {
    // Simulate real-time updates
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      yield _posts.where((post) => !post.isClosed).toList();
    }
  }

  Future<int> getUserActivePostCount(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    return _posts
        .where((post) => post.userId == userId && !post.isClosed)
        .length;
  }

  Future<LfgPostModel?> getLfgPostById(String postId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      return _posts.firstWhere((p) => p.id == postId);
    } catch (e) {
      return null;
    }
  }
} 