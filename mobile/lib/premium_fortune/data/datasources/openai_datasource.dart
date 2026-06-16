import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/pf_config.dart';
import '../../core/errors/pf_failure.dart';

/// OpenAI Chat Completions API istemcisi.
class OpenAiDatasource {
  OpenAiDatasource({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<Map<String, String>> analyzeCoffeeCup({
    required String imageUrl,
    String? imageBase64,
  }) async {
    if (!PfConfig.hasOpenAi) {
      return _demoCoffeeReading();
    }

    final content = <Map<String, dynamic>>[
      {
        'type': 'text',
        'text':
            'Bu kahve fincanı fotoğrafını Türkçe analiz et. JSON döndür: '
            '{"summary":"...","love":"...","money":"...","career":"...","health":"..."} '
            'Her alan 2-4 cümle, mistik ama pozitif ton.',
      },
    ];

    if (imageBase64 != null && imageBase64.isNotEmpty) {
      content.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'},
      });
    } else if (imageUrl.isNotEmpty) {
      content.add({
        'type': 'image_url',
        'image_url': {'url': imageUrl},
      });
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${PfConfig.openAiApiKey}',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
        ),
        data: {
          'model': PfConfig.openAiModel,
          'messages': [
            {'role': 'user', 'content': content},
          ],
          'max_tokens': 1200,
          'response_format': {'type': 'json_object'},
        },
      );

      final text = response.data?['choices']?[0]?['message']?['content'] as String?;
      if (text == null || text.isEmpty) {
        throw const PfAiFailure('AI yanıtı boş.');
      }

      final parsed = jsonDecode(text) as Map<String, dynamic>;
      return {
        'summary': parsed['summary']?.toString() ?? '',
        'love': parsed['love']?.toString() ?? '',
        'money': parsed['money']?.toString() ?? '',
        'career': parsed['career']?.toString() ?? '',
        'health': parsed['health']?.toString() ?? '',
      };
    } on DioException catch (e) {
      debugPrint('OpenAI coffee error: ${e.message}');
      throw PfAiFailure(e.message ?? 'AI servisi yanıt vermedi.');
    }
  }

  Future<String> interpretTarot({
    required List<String> cardNames,
    required String mode,
  }) async {
    if (!PfConfig.hasOpenAi) {
      return _demoTarotReading(cardNames, mode);
    }

    final prompt =
        'Sen deneyimli bir tarot falcısısın. Mod: $mode. '
        'Seçilen kartlar: ${cardNames.join(", ")}. '
        'Türkçe, detaylı ve mistik bir yorum yaz (4-6 paragraf).';

    return _chat(prompt);
  }

  Future<String> interpretDream(String dreamText) async {
    if (!PfConfig.hasOpenAi) {
      return 'Rüyanızda gördüğünüz semboller bilinçaltınızın size mesaj verme '
          'biçimidir. $dreamText — bu rüya değişim ve içsel dönüşüm enerjisi taşıyor. '
          'Yakın zamanda hayatınızda yeni bir kapı açılabilir; sezgilerinize güvenin.';
    }

    final prompt =
        'Rüya tabiri uzmanı olarak şu rüyayı Türkçe yorumla (3-5 paragraf): $dreamText';

    return _chat(prompt);
  }

  Future<Map<String, String>> interpretBirthChart({
    required String sun,
    required String moon,
    required String rising,
  }) async {
    if (!PfConfig.hasOpenAi) {
      return {
        'interpretation':
            'Güneş burcunuz $sun, Ay burcunuz $moon, Yükselen burcunuz $rising. '
            'Bu kombinasyon güçlü bir sezgi ve liderlik enerjisi taşır. '
            'İlişkilerde derinlik, kariyerde ise yaratıcı atılımlar ön planda.',
      };
    }

    final text = await _chat(
      'Doğum haritası yorumu yaz. Güneş: $sun, Ay: $moon, Yükselen: $rising. Türkçe, 4 paragraf.',
    );
    return {'interpretation': text};
  }

  Future<String> _chat(String prompt) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${PfConfig.openAiApiKey}',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: {
          'model': PfConfig.openAiModel,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1000,
        },
      );

      final text = response.data?['choices']?[0]?['message']?['content'] as String?;
      if (text == null || text.isEmpty) {
        throw const PfAiFailure('AI yanıtı boş.');
      }
      return text.trim();
    } on DioException catch (e) {
      throw PfAiFailure(e.message ?? 'AI servisi yanıt vermedi.');
    }
  }

  Map<String, String> _demoCoffeeReading() => const {
        'summary':
            'Fincanınızda güçlü bir dönüşüm enerjisi görünüyor. Yakın gelecekte '
            'beklenmedik güzel haberler kapınızı çalabilir.',
        'love':
            'Kalbinizde biriken duygular yakında açığa çıkacak. İlişkinizde '
            'samimiyet ve güven artacak.',
        'money':
            'Maddi konularda sabırlı olun; küçük adımlar büyük kazançlara '
            'dönüşebilir. Beklenmedik bir fırsat yaklaşıyor.',
        'career':
            'İş hayatınızda yaratıcı bir dönem başlıyor. Cesur kararlar '
            'almaktan çekinmeyin.',
        'health':
            'Enerjiniz yükseliyor. Dinlenmeye ve su tüketimine özen gösterin; '
            'bedeniniz size teşekkür edecek.',
      };

  String _demoTarotReading(List<String> cards, String mode) {
    return '$mode tarot okumanızda ${cards.join(", ")} kartları çıktı. '
        'Bu kartlar birlikte güçlü bir dönüşüm döngüsünü işaret ediyor. '
        'Geçmişinizden gelen dersler, bugünkü cesaretinizle birleşerek '
        'geleceğinize yeni kapılar açacak. Sezgilerinize güvenin ve '
        'kalbinizin sesini dinleyin.';
  }
}
