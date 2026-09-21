import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_provider.dart';

// Models
class VoiceFortune {
  final String id;
  final String userId;
  final String audioUrl;
  final int duration;
  final String? transcription;
  final String transcriptionLanguage;
  final double? confidenceScore;
  final String? fortuneId;
  final String processingStatus;
  final String? processingError;
  final DateTime createdAt;
  final DateTime? processedAt;

  VoiceFortune({
    required this.id,
    required this.userId,
    required this.audioUrl,
    required this.duration,
    this.transcription,
    this.transcriptionLanguage = 'tr',
    this.confidenceScore,
    this.fortuneId,
    required this.processingStatus,
    this.processingError,
    required this.createdAt,
    this.processedAt,
  });

  factory VoiceFortune.fromJson(Map<String, dynamic> json) {
    return VoiceFortune(
      id: json['id'] as String,
      userId: json['userId'] as String,
      audioUrl: json['audioUrl'] as String,
      duration: json['duration'] as int,
      transcription: json['transcription'] as String?,
      transcriptionLanguage: json['transcriptionLanguage'] as String? ?? 'tr',
      confidenceScore: json['confidenceScore'] != null
          ? (json['confidenceScore'] as num).toDouble()
          : null,
      fortuneId: json['fortuneId'] as String?,
      processingStatus: json['processingStatus'] as String,
      processingError: json['processingError'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
    );
  }
}

class VoiceProcessingJob {
  final String id;
  final String voiceFortuneId;
  final String status;
  final int progress;
  final String provider;
  final String? providerJobId;
  final String? error;
  final int retryCount;
  final DateTime? startedAt;
  final DateTime? completedAt;

  VoiceProcessingJob({
    required this.id,
    required this.voiceFortuneId,
    required this.status,
    required this.progress,
    required this.provider,
    this.providerJobId,
    this.error,
    required this.retryCount,
    this.startedAt,
    this.completedAt,
  });

  factory VoiceProcessingJob.fromJson(Map<String, dynamic> json) {
    return VoiceProcessingJob(
      id: json['id'] as String,
      voiceFortuneId: json['voiceFortuneId'] as String,
      status: json['status'] as String,
      progress: json['progress'] as int,
      provider: json['provider'] as String,
      providerJobId: json['providerJobId'] as String?,
      error: json['error'] as String?,
      retryCount: json['retryCount'] as int,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      completedAt:
          json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    );
  }
}

// Service
class VoiceFortuneService {
  final Dio _dio;

  VoiceFortuneService(this._dio);

  Future<Map<String, dynamic>> uploadAudio(String filePath) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(filePath),
    });

    final response = await _dio.post(
      '/api/voice-fortune/upload',
      data: formData,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<String> transcribeAudio(String voiceFortuneId) async {
    final response = await _dio.post('/api/voice-fortune/$voiceFortuneId/transcribe');
    return response.data['data']['transcription'] as String;
  }

  Future<Map<String, dynamic>> generateFortuneFromVoice(String voiceFortuneId) async {
    final response =
        await _dio.post('/api/voice-fortune/$voiceFortuneId/generate-fortune');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<VoiceFortune>> getVoiceFortunes({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/api/voice-fortune/',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return (response.data['data']['voiceFortunes'] as List)
        .map((v) => VoiceFortune.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  Future<VoiceFortune> getVoiceFortuneDetail(String voiceFortuneId) async {
    final response = await _dio.get('/api/voice-fortune/$voiceFortuneId');
    return VoiceFortune.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<VoiceProcessingJob> getProcessingStatus(String voiceFortuneId) async {
    final response = await _dio.get('/api/voice-fortune/$voiceFortuneId/status');
    return VoiceProcessingJob.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteVoiceFortune(String voiceFortuneId) async {
    await _dio.delete('/api/voice-fortune/$voiceFortuneId');
  }
}

// Providers
final voiceFortuneServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return VoiceFortuneService(dio);
});

final voiceFortuesProvider = FutureProvider.family<
  List<VoiceFortune>,
  ({int limit, int offset})
>((ref, params) async {
  final service = ref.watch(voiceFortuneServiceProvider);
  return service.getVoiceFortunes(
    limit: params.limit,
    offset: params.offset,
  );
});

final voiceFortuneDetailProvider = FutureProvider.family<VoiceFortune, String>(
  (ref, voiceFortuneId) async {
    final service = ref.watch(voiceFortuneServiceProvider);
    return service.getVoiceFortuneDetail(voiceFortuneId);
  },
);

final voiceProcessingStatusProvider = FutureProvider.family<VoiceProcessingJob, String>(
  (ref, voiceFortuneId) async {
    final service = ref.watch(voiceFortuneServiceProvider);
    return service.getProcessingStatus(voiceFortuneId);
  },
);

// Upload audio notifier
class UploadAudioNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final VoiceFortuneService _service;

  UploadAudioNotifier(this._service) : super(const AsyncValue.data({}));

  Future<void> upload(String filePath) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.uploadAudio(filePath));
  }
}

final uploadAudioProvider =
    StateNotifierProvider<UploadAudioNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) => UploadAudioNotifier(ref.watch(voiceFortuneServiceProvider)),
);

// Transcribe audio notifier
class TranscribeAudioNotifier extends StateNotifier<AsyncValue<String>> {
  final VoiceFortuneService _service;

  TranscribeAudioNotifier(this._service) : super(const AsyncValue.data(''));

  Future<void> transcribe(String voiceFortuneId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.transcribeAudio(voiceFortuneId));
  }
}

final transcribeAudioProvider = StateNotifierProvider<TranscribeAudioNotifier, AsyncValue<String>>(
  (ref) => TranscribeAudioNotifier(ref.watch(voiceFortuneServiceProvider)),
);

// Generate fortune notifier
class GenerateVoiceFortuneNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final VoiceFortuneService _service;

  GenerateVoiceFortuneNotifier(this._service) : super(const AsyncValue.data({}));

  Future<void> generate(String voiceFortuneId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.generateFortuneFromVoice(voiceFortuneId));
  }
}

final generateVoiceFortuneProvider =
    StateNotifierProvider<GenerateVoiceFortuneNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) => GenerateVoiceFortuneNotifier(ref.watch(voiceFortuneServiceProvider)),
);
