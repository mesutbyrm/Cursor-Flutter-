import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_provider.dart';

// Models
class AICopilotSuggestion {
  final String id;
  final String userId;
  final String? fortuneId;
  final String prompt;
  final String suggestion;
  final double confidenceScore;
  final String analysisType;
  final bool liked;
  final int? rating;
  final DateTime createdAt;

  AICopilotSuggestion({
    required this.id,
    required this.userId,
    this.fortuneId,
    required this.prompt,
    required this.suggestion,
    required this.confidenceScore,
    required this.analysisType,
    required this.liked,
    this.rating,
    required this.createdAt,
  });

  factory AICopilotSuggestion.fromJson(Map<String, dynamic> json) {
    return AICopilotSuggestion(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fortuneId: json['fortuneId'] as String?,
      prompt: json['prompt'] as String,
      suggestion: json['suggestion'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      analysisType: json['analysisType'] as String,
      liked: json['liked'] as bool? ?? false,
      rating: json['rating'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AICopilotHistory {
  final String id;
  final String copilotId;
  final String action;
  final DateTime timestamp;

  AICopilotHistory({
    required this.id,
    required this.copilotId,
    required this.action,
    required this.timestamp,
  });

  factory AICopilotHistory.fromJson(Map<String, dynamic> json) {
    return AICopilotHistory(
      id: json['id'] as String,
      copilotId: json['copilotId'] as String,
      action: json['action'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

// Service
class AICopilotService {
  final Dio _dio;

  AICopilotService(this._dio);

  Future<AICopilotSuggestion> generateSuggestion({
    required String prompt,
    String? fortuneId,
    String analysisType = 'general',
    Map<String, dynamic>? context,
  }) async {
    final response = await _dio.post(
      '/api/ai-copilot/suggestions',
      data: {
        'prompt': prompt,
        'fortuneId': fortuneId,
        'analysisType': analysisType,
        'context': context,
      },
    );
    return AICopilotSuggestion.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<AICopilotSuggestion>> getSuggestions({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/api/ai-copilot/suggestions',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return (response.data['data']['suggestions'] as List)
        .map((s) => AICopilotSuggestion.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<void> rateSuggestion(String copilotId, int rating) async {
    await _dio.put(
      '/api/ai-copilot/suggestions/$copilotId/rating',
      data: {'rating': rating},
    );
  }

  Future<void> deleteSuggestion(String copilotId) async {
    await _dio.delete('/api/ai-copilot/suggestions/$copilotId');
  }

  Future<List<AICopilotHistory>> getSuggestionHistory(String copilotId) async {
    final response = await _dio.get('/api/ai-copilot/suggestions/$copilotId/history');
    return (response.data['data']['history'] as List)
        .map((h) => AICopilotHistory.fromJson(h as Map<String, dynamic>))
        .toList();
  }
}

// Providers
final aiCopilotServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AICopilotService(dio);
});

final aiCopilotSuggestionsProvider = FutureProvider.family<
  List<AICopilotSuggestion>,
  ({int limit, int offset})
>((ref, params) async {
  final service = ref.watch(aiCopilotServiceProvider);
  return service.getSuggestions(
    limit: params.limit,
    offset: params.offset,
  );
});

// Generate suggestion notifier
class GenerateSuggestionNotifier extends StateNotifier<AsyncValue<AICopilotSuggestion>> {
  final AICopilotService _service;

  GenerateSuggestionNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> generate({
    required String prompt,
    String? fortuneId,
    String analysisType = 'general',
    Map<String, dynamic>? context,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.generateSuggestion(
        prompt: prompt,
        fortuneId: fortuneId,
        analysisType: analysisType,
        context: context,
      ),
    );
  }
}

final generateSuggestionProvider =
    StateNotifierProvider<GenerateSuggestionNotifier, AsyncValue<AICopilotSuggestion>>(
  (ref) => GenerateSuggestionNotifier(ref.watch(aiCopilotServiceProvider)),
);

// Rate suggestion notifier
class RateSuggestionNotifier extends StateNotifier<AsyncValue<void>> {
  final AICopilotService _service;

  RateSuggestionNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> rate(String copilotId, int rating) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.rateSuggestion(copilotId, rating));
  }
}

final rateSuggestionProvider = StateNotifierProvider<RateSuggestionNotifier, AsyncValue<void>>(
  (ref) => RateSuggestionNotifier(ref.watch(aiCopilotServiceProvider)),
);
