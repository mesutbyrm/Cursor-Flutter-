import 'dart:math';

import '../../domain/entities/fortune_type_entity.dart';
import '../data/fortune_catalog.dart';

/// Yerel fal yorumu üretici (API yokken premium deneyim).
class FortuneReadingService {
  FortuneReadingService({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  FortuneReadingResult generate(
    FortuneTypeEntity type, {
    String? userInput,
    bool? yesNoChoice,
  }) {
    if (type.isDaily) {
      return FortuneReadingResult(
        type: type,
        summary: 'Enerjin yükseliyor; doğru zamandasın.',
        detail:
            'Günlük Fal yorumun kişisel enerjine göre hazırlandı. '
            'Kendini keşfet, geleceğini aydınlat; iç huzurunu koru; evren seninle.',
        luckyNumber: 7 + DateTime.now().day % 23,
        luckyColor: const ['Mor', 'Pembe', 'Altın', 'Turkuaz', 'Mavi'][
            DateTime.now().weekday % 5],
      );
    }
    final summaries = _summariesFor(type, yesNoChoice);
    final summary = summaries[_rng.nextInt(summaries.length)];
    final detail = _detailFor(type, userInput, yesNoChoice);

    return FortuneReadingResult(
      type: type,
      summary: summary,
      detail: detail,
      luckyNumber: 1 + _rng.nextInt(99),
      luckyColor: ['Mor', 'Pembe', 'Altın', 'Turkuaz', 'Mavi'][_rng.nextInt(5)],
    );
  }

  List<String> _summariesFor(FortuneTypeEntity type, bool? yesNo) =>
      switch (type.kind) {
        FortuneSessionKind.yesNo => [
            yesNo == true
                ? 'Evet — evren senin lehine işliyor.'
                : 'Hayır — şimdilik beklemek daha iyi.',
          ],
        FortuneSessionKind.loveHeart => [
          'Kalbin açık ve sevgiye hazır.',
          'Yakında güzel bir sürpriz seni bekliyor.',
        ],
        _ => [
          'Enerjin yükseliyor; doğru zamandasın.',
          'İç sesine güven; yolun aydınlanacak.',
          'Sabırlı ol; güzel gelişmeler yakın.',
        ],
      };

  String _detailFor(
    FortuneTypeEntity type,
    String? input,
    bool? yesNo,
  ) {
    final name = type.title;
    final extra = (input != null && input.trim().isNotEmpty)
        ? '\n\nPaylaştığın not: «${input.trim()}»'
        : '';
    return switch (type.kind) {
      FortuneSessionKind.tarotCards =>
        '$name kartları geçmiş, şimdi ve gelecek hattında uyum gösteriyor. '
        'Önündeki dönemde cesur adımlar seni bekliyor.$extra',
      FortuneSessionKind.coffeeCup =>
        'Fincanında beliren desenler değişim ve yeni başlangıçları işaret ediyor. '
        'Sosyal çevrende sıcak bir haber alabilirsin.$extra',
      FortuneSessionKind.zodiacWheel =>
        'Gökyüzü senin için destekleyici bir konumda. '
        'Yaratıcılığını öne çıkarman önerilir.$extra',
      FortuneSessionKind.dreamText =>
        'Rüyan sembolik bir dönüşümü anlatıyor. '
        'Bastırdığın bir isteğin yüzeye çıkma zamanı gelmiş olabilir.$extra',
      FortuneSessionKind.numberInput =>
        'Sayıların titreşimi güçlü bir dönem sinyali veriyor. '
        'Hedeflerine odaklan; disiplin seni ödüllendirecek.$extra',
      FortuneSessionKind.yesNo =>
        yesNo == true
            ? 'Evet cevabı net: fırsatı değerlendir, tereddüt etme.'
            : 'Hayır cevabı: acele etme, daha uygun bir zaman gelecek.',
      _ =>
        '$name yorumun kişisel enerjine göre hazırlandı. '
        '${FortuneCatalog.tagline} İç huzurunu koru; evren seninle.$extra',
    };
  }
}
