import '../../domain/entities/pf_astrology.dart';
import 'openai_datasource.dart';

class PfAstrologyDatasource {
  PfAstrologyDatasource({OpenAiDatasource? openAi})
      : _openAi = openAi ?? OpenAiDatasource();

  final OpenAiDatasource _openAi;

  static const signs = [
    'Koç', 'Boğa', 'İkizler', 'Yengeç', 'Aslan', 'Başak',
    'Terazi', 'Akrep', 'Yay', 'Oğlak', 'Kova', 'Balık',
  ];

  static const _dailyTemplates = {
    'Koç': 'Bugün enerjiniz zirvede. Cesur adımlar atın, liderlik rolünüzü sahiplenin.',
    'Boğa': 'Maddi konularda istikrar ön planda. Sabırlı olun, güzel sonuçlar yakın.',
    'İkizler': 'İletişim gücünüz artıyor. Yeni bağlantılar ve fikirler kapınızı çalabilir.',
    'Yengeç': 'Duygusal derinlik gününüz. Aile ve yakın çevreyle zaman geçirin.',
    'Aslan': 'Parlak bir gün sizi bekliyor. Yaratıcılığınızı serbest bırakın.',
    'Başak': 'Detaylara odaklanın. Organize olun, küçük iyileştirmeler büyük fark yaratır.',
    'Terazi': 'Denge ve uyum arayışındasınız. İlişkilerde diplomasi ön planda.',
    'Akrep': 'Dönüşüm enerjisi güçlü. Derin içgörüler ve sezgisel farkındalık.',
    'Yay': 'Macera ve keşif ruhu aktif. Ufkunuzu genişleten fırsatlar yakın.',
    'Oğlak': 'Disiplin ve kararlılık ödüllendirilecek. Kariyer hedeflerinize odaklanın.',
    'Kova': 'Yenilikçi fikirler gündemde. Topluluk ve arkadaşlık bağları güçleniyor.',
    'Balık': 'Sezgileriniz keskin. Sanatsal ve ruhsal aktivitelere zaman ayırın.',
  };

  Future<PfHoroscopeReading> getHoroscope(String sign) async {
    final daily = _dailyTemplates[sign] ??
        'Bugün evren size özel mesajlar gönderiyor. Açık kalın ve sezgilerinize güvenin.';
    return PfHoroscopeReading(
      sign: sign,
      daily: daily,
      weekly:
          '$sign burcu için bu hafta: İlişkilerde derinleşme, iş hayatında yeni fırsatlar '
          've kişisel gelişim için güçlü bir dönem. Perşembe ve Cuma özellikle şanslı günler.',
      updatedAt: DateTime.now(),
    );
  }

  Future<PfBirthChart> createBirthChart({
    required String userId,
    required DateTime birthDate,
    required String birthPlace,
    required double latitude,
    required double longitude,
  }) async {
    final month = birthDate.month;
    final sun = signs[(month - 1) % 12];
    final moon = signs[(month + 3) % 12];
    final rising = signs[(month + 6) % 12];

    final result = await _openAi.interpretBirthChart(
      sun: sun,
      moon: moon,
      rising: rising,
    );

    return PfBirthChart(
      id: 'chart_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      sunSign: sun,
      moonSign: moon,
      risingSign: rising,
      interpretation: result['interpretation'] ?? '',
      createdAt: DateTime.now(),
    );
  }
}
