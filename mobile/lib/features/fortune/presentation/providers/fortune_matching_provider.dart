import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_provider.dart';

// Models
class FortuneMatch {
  final String id;
  final String userId1;
  final String userId2;
  final double compatibilityScore;
  final String matchType;
  final String? analysis;
  final Map<String, dynamic>? insights;
  final List<String> recommendations;
  final bool shared;
  final DateTime? sharedAt;
  final DateTime createdAt;

  FortuneMatch({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.compatibilityScore,
    required this.matchType,
    this.analysis,
    this.insights,
    required this.recommendations,
    required this.shared,
    this.sharedAt,
    required this.createdAt,
  });

  factory FortuneMatch.fromJson(Map<String, dynamic> json) {
    return FortuneMatch(
      id: json['id'] as String,
      userId1: json['userId1'] as String,
      userId2: json['userId2'] as String,
      compatibilityScore: (json['compatibilityScore'] as num).toDouble(),
      matchType: json['matchType'] as String,
      analysis: json['analysis'] as String?,
      insights: json['insights'] as Map<String, dynamic>?,
      recommendations: List<String>.from(json['recommendations'] as List? ?? []),
      shared: json['shared'] as bool? ?? false,
      sharedAt: json['sharedAt'] != null ? DateTime.parse(json['sharedAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class FortuneMatchView {
  final String id;
  final String userId;
  final String matchId;
  final DateTime viewedAt;

  FortuneMatchView({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.viewedAt,
  });

  factory FortuneMatchView.fromJson(Map<String, dynamic> json) {
    return FortuneMatchView(
      id: json['id'] as String,
      userId: json['userId'] as String,
      matchId: json['matchId'] as String,
      viewedAt: DateTime.parse(json['viewedAt'] as String),
    );
  }
}

// Service
class FortuneMatchingService {
  final Dio _dio;

  FortuneMatchingService(this._dio);

  Future<FortuneMatch> createMatch({
    required String userId2,
    String? fortuneId1,
    String? fortuneId2,
  }) async {
    final response = await _dio.post(
      '/api/fortune-matching/matches',
      data: {
        'userId2': userId2,
        'fortuneId1': fortuneId1,
        'fortuneId2': fortuneId2,
      },
    );
    return FortuneMatch.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<FortuneMatch>> getMatches({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/api/fortune-matching/matches',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return (response.data['data']['matches'] as List)
        .map((m) => FortuneMatch.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<FortuneMatch> getMatchDetail(String matchId) async {
    final response = await _dio.get('/api/fortune-matching/matches/$matchId');
    return FortuneMatch.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> shareMatch(String matchId) async {
    await _dio.put('/api/fortune-matching/matches/$matchId/share');
  }

  Future<void> recordView(String matchId) async {
    await _dio.post('/api/fortune-matching/matches/$matchId/view');
  }

  Future<List<FortuneMatchView>> getMatchHistory(String matchId) async {
    final response = await _dio.get('/api/fortune-matching/matches/$matchId/history');
    return (response.data['data']['history'] as List)
        .map((h) => FortuneMatchView.fromJson(h as Map<String, dynamic>))
        .toList();
  }
}

// Providers
final fortuneMatchingServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return FortuneMatchingService(dio);
});

final fortuneMatchesProvider = FutureProvider.family<
  List<FortuneMatch>,
  ({int limit, int offset})
>((ref, params) async {
  final service = ref.watch(fortuneMatchingServiceProvider);
  return service.getMatches(
    limit: params.limit,
    offset: params.offset,
  );
});

final fortuneMatchDetailProvider = FutureProvider.family<FortuneMatch, String>(
  (ref, matchId) async {
    final service = ref.watch(fortuneMatchingServiceProvider);
    return service.getMatchDetail(matchId);
  },
);

// Create match notifier
class CreateMatchNotifier extends StateNotifier<AsyncValue<FortuneMatch>> {
  final FortuneMatchingService _service;

  CreateMatchNotifier(this._service) : super(const AsyncValue.data(null as dynamic));

  Future<void> create({
    required String userId2,
    String? fortuneId1,
    String? fortuneId2,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.createMatch(
        userId2: userId2,
        fortuneId1: fortuneId1,
        fortuneId2: fortuneId2,
      ),
    );
  }
}

final createMatchProvider =
    StateNotifierProvider<CreateMatchNotifier, AsyncValue<FortuneMatch>>(
  (ref) => CreateMatchNotifier(ref.watch(fortuneMatchingServiceProvider)),
);

// Share match notifier
class ShareMatchNotifier extends StateNotifier<AsyncValue<void>> {
  final FortuneMatchingService _service;

  ShareMatchNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> share(String matchId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.shareMatch(matchId));
  }
}

final shareMatchProvider = StateNotifierProvider<ShareMatchNotifier, AsyncValue<void>>(
  (ref) => ShareMatchNotifier(ref.watch(fortuneMatchingServiceProvider)),
);
