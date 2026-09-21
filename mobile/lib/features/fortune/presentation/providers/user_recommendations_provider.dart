import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserRecommendation {
  final String userId;
  final String recommendedUserId;
  final String reason;
  final double score;
  final int interactionCount;
  final Map<String, dynamic>? recommendedUser;

  UserRecommendation({
    required this.userId,
    required this.recommendedUserId,
    required this.reason,
    required this.score,
    this.interactionCount = 0,
    this.recommendedUser,
  });

  factory UserRecommendation.fromJson(Map<String, dynamic> json) {
    return UserRecommendation(
      userId: json['userId'] ?? '',
      recommendedUserId: json['recommendedUserId'] ?? '',
      reason: json['reason'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      interactionCount: json['interactionCount'] ?? 0,
      recommendedUser: json['recommendedUser'],
    );
  }
}

class UserRecommendationService {
  Future<List<UserRecommendation>> getRecommendations(String userId, {int limit = 20, int offset = 0}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<UserRecommendation> createRecommendation(String userId, String recommendedUserId, String reason, double score) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return UserRecommendation(
      userId: userId,
      recommendedUserId: recommendedUserId,
      reason: reason,
      score: score,
    );
  }

  Future<void> deleteRecommendation(String userId, String recommendedUserId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<List<UserRecommendation>> getSimilarUsers(String userId, {int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<void> incrementInteraction(String userId, String recommendedUserId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

final userRecommendationServiceProvider = Provider((ref) => UserRecommendationService());

final userRecommendationsProvider = FutureProvider.family<List<UserRecommendation>, (String, int, int)>((ref, params) async {
  final service = ref.watch(userRecommendationServiceProvider);
  return service.getRecommendations(params.$1, limit: params.$2, offset: params.$3);
});

final similarUsersProvider = FutureProvider.family<List<UserRecommendation>, (String, int)>((ref, params) async {
  final service = ref.watch(userRecommendationServiceProvider);
  return service.getSimilarUsers(params.$1, limit: params.$2);
});

class CreateRecommendationNotifier extends StateNotifier<AsyncValue<UserRecommendation?>> {
  CreateRecommendationNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> create(String userId, String recommendedUserId, String reason, double score) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(userRecommendationServiceProvider);
      final recommendation = await service.createRecommendation(userId, recommendedUserId, reason, score);
      state = AsyncValue.data(recommendation);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final createRecommendationNotifierProvider = StateNotifierProvider<CreateRecommendationNotifier, AsyncValue<UserRecommendation?>>((ref) {
  return CreateRecommendationNotifier(ref);
});
