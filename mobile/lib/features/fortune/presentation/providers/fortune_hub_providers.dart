import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/domain/home_zodiac_signs.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/fortune_hub_preferences_store.dart';
import '../../domain/fortune_zodiac.dart';
import '../providers/fortune_api_providers.dart';
import 'fortune_birth_profile_provider.dart';

final fortuneHubPreferencesStoreProvider =
    FutureProvider<FortuneHubPreferencesStore>((ref) async {
  return FortuneHubPreferencesStore.create();
});

final fortuneHubSearchQueryProvider = StateProvider<String>((ref) => '');

/// Günlük burç + enerji kartları için özet.
class FortuneDailyInsights {
  const FortuneDailyInsights({
    required this.energyLabel,
    required this.luckyColor,
    required this.luckyNumber,
    required this.moonPhase,
    required this.burcMessage,
    this.horoscopeText,
    this.zodiacSign,
  });

  final String energyLabel;
  final String luckyColor;
  final String luckyNumber;
  final String moonPhase;
  final String burcMessage;
  final String? horoscopeText;
  final String? zodiacSign;

  static FortuneDailyInsights fallback() {
    final now = DateTime.now();
    return FortuneDailyInsights(
      energyLabel: 'Yüksek',
      luckyColor: 'Mor',
      luckyNumber: '${(now.day + now.month) % 9 + 1}',
      moonPhase: _moonPhaseFor(now),
      burcMessage: 'Bugün iç sesine kulak ver.',
    );
  }
}

final fortuneDailyInsightsProvider =
    FutureProvider<FortuneDailyInsights>((ref) async {
  final profile = await ref.watch(fortuneBirthProfileProvider.future);
  final now = DateTime.now();
  final luckyNumber = '${(now.day + now.month) % 9 + 1}';
  final moonPhase = _moonPhaseFor(now);

  if (profile == null) {
    return FortuneDailyInsights.fallback();
  }

  final zodiac = FortuneZodiac.fromBirthDate(profile.birthDate);
  final apiSign = HomeZodiacSigns.apiValueFor(zodiac.sign);
  final horoscope = await ref
      .read(homeRemoteProvider)
      .fetchDailyHoroscope(apiSign);

  final message = horoscope != null && horoscope.trim().isNotEmpty
      ? _firstSentence(horoscope)
      : 'Bugün $zodiac.sign burcu için yeni bir kapı açılıyor.';

  return FortuneDailyInsights(
    energyLabel: _energyFor(now),
    luckyColor: _colorForSign(zodiac.sign),
    luckyNumber: luckyNumber,
    moonPhase: moonPhase,
    burcMessage: message,
    horoscopeText: horoscope,
    zodiacSign: zodiac.sign,
  );
});

String _firstSentence(String text) {
  final t = text.trim();
  final dot = t.indexOf('.');
  if (dot > 20 && dot < 120) return t.substring(0, dot + 1);
  if (t.length <= 96) return t;
  return '${t.substring(0, 93)}…';
}

String _energyFor(DateTime now) {
  final bucket = (now.day + now.month) % 3;
  return switch (bucket) {
    0 => 'Yüksek',
    1 => 'Dengeli',
    _ => 'Sakin',
  };
}

String _colorForSign(String sign) => switch (sign) {
      'Koç' || 'Aslan' || 'Yay' => 'Altın',
      'Boğa' || 'Başak' || 'Oğlak' => 'Yeşil',
      'İkizler' || 'Terazi' || 'Kova' => 'Mavi',
      'Yengeç' || 'Akrep' || 'Balık' => 'Mor',
      _ => 'Mor',
    };

String _moonPhaseFor(DateTime date) {
  const phases = [
    'Yeni Ay',
    'Hilal',
    'İlk Dördün',
    'Şişkin Ay',
    'Dolunay',
    'Şişkin Ay',
    'Son Dördün',
    'Hilal',
  ];
  final synodic = 29.53058867;
  final known = DateTime.utc(2000, 1, 6, 18, 14);
  final days = date.toUtc().difference(known).inHours / 24.0;
  final phase = ((days % synodic) / synodic * 8).floor() % 8;
  return phases[phase];
}

/// Sosyal kanıt metni — sahte sayı yerine kullanıcıya özel özet.
final fortuneHubSocialProofProvider = Provider<String>((ref) {
  final history = ref.watch(fortuneHistoryProvider).valueOrNull;
  final count = history?.length ?? 0;
  if (count > 0) {
    return '$count fal kaydın var — bugün yeni bir kehanet keşfet';
  }
  return 'Kişisel fal yolculuğuna bugün başlamaya hazır mısın?';
});

bool fortuneHubMatchesSearch({
  required String query,
  required String title,
  required String slug,
  String? subtitle,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (title.toLowerCase().contains(q)) return true;
  if (slug.toLowerCase().contains(q)) return true;
  final sub = subtitle?.toLowerCase();
  return sub != null && sub.contains(q);
}
