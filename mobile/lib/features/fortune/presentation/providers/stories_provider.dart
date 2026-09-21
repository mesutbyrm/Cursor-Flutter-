import 'package:flutter_riverpod/flutter_riverpod.dart';

class Story {
  final String id;
  final String userId;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final int viewCount;
  final int likeCount;
  final DateTime expiresAt;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    this.viewCount = 0,
    this.likeCount = 0,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'],
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      expiresAt: DateTime.parse(json['expiresAt']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class StoriesService {
  Future<String> createStory(String userId, String content, {String? mediaUrl, String? mediaType}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'story_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<List<Story>> getActiveStories(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<List<Story>> getFollowingStories(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<List<Story>> getUserStories(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<void> viewStory(String storyId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> reactToStory(String storyId, String userId, String emoji) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> deleteStory(String storyId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

final storiesServiceProvider = Provider((ref) => StoriesService());

final activeStoriesProvider = FutureProvider.family<List<Story>, String>((ref, userId) async {
  final service = ref.watch(storiesServiceProvider);
  return service.getActiveStories(userId);
});

final followingStoriesProvider = FutureProvider.family<List<Story>, String>((ref, userId) async {
  final service = ref.watch(storiesServiceProvider);
  return service.getFollowingStories(userId);
});

final userStoriesProvider = FutureProvider.family<List<Story>, String>((ref, userId) async {
  final service = ref.watch(storiesServiceProvider);
  return service.getUserStories(userId);
});

class CreateStoryNotifier extends StateNotifier<AsyncValue<String?>> {
  CreateStoryNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> createStory(String userId, String content, {String? mediaUrl, String? mediaType}) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(storiesServiceProvider);
      final storyId = await service.createStory(userId, content, mediaUrl: mediaUrl, mediaType: mediaType);
      state = AsyncValue.data(storyId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final createStoryNotifierProvider = StateNotifierProvider<CreateStoryNotifier, AsyncValue<String?>>((ref) {
  return CreateStoryNotifier(ref);
});

class ReactStoryNotifier extends StateNotifier<AsyncValue<void>> {
  ReactStoryNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> react(String storyId, String userId, String emoji) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(storiesServiceProvider);
      await service.reactToStory(storyId, userId, emoji);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final reactStoryNotifierProvider = StateNotifierProvider<ReactStoryNotifier, AsyncValue<void>>((ref) {
  return ReactStoryNotifier(ref);
});
