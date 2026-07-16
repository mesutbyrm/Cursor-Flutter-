import '../core/network/api_endpoints.dart';
import '../core/sse_client.dart';

/// Fal API — kılavuz §9.5 `FortuneRepository` (SSE streaming).
class FortuneService {
  FortuneService({SseClient? sseClient}) : _sseClient = sseClient;

  final SseClient? _sseClient;

  /// İngilizce / kısa tip → üretim slug.
  static const fortuneTypeSlugs = <String, String>{
    'coffee': 'kahve-fali',
    'tarot': 'tarot-fali',
    'dream': 'ruya-yorumu',
    'horoscope': 'burc-yorumu',
    'love': 'ask-uyumu',
    'palm': 'el-fali',
    'angel': 'melek-kartlari',
    'numerology': 'numeroloji',
    'aura': 'aura-analizi',
    'yesno': 'evet-hayir',
    'birthchart': 'dogum-haritasi',
    'istihare': 'istihare',
    'katina': 'katina',
    'kursundokme': 'kursundokme',
  };

  static String resolveSlug(String type) {
    final key = type.trim().toLowerCase();
    return fortuneTypeSlugs[key] ?? key;
  }

  /// `POST /api/fortunes/{type}` — SSE stream.
  Stream<SseFortuneChunk> generateFortune(
    String type,
    Map<String, dynamic> body, {
    String? accessToken,
  }) {
    final client = _sseClient;
    if (client == null) {
      throw StateError(
        'Fal SSE için FortuneService oluşturulurken SseClient verilmelidir.',
      );
    }
    final slug = resolveSlug(type);
    return client.fortuneReadingStream(
      fortuneType: slug,
      body: {
        'language': 'tr',
        'platform': 'mobile',
        ...body,
      },
      accessToken: accessToken,
    );
  }
}
