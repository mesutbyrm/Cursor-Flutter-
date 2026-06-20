import 'dart:math';

import '../../domain/entities/fortune_reading_section.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../data/fortune_catalog.dart';
import 'fortune_section_parser.dart';
import 'fortune_visual_analysis.dart';

/// Yerel fal yorumu üretici — yapılandırılmış 200–500 kelime premium deneyim.
class FortuneReadingService {
  FortuneReadingService({
    Random? random,
    FortuneVisualAnalysis? visualAnalysis,
    FortuneSectionParser? sectionParser,
  })  : _rng = random ?? Random(),
        _visual = visualAnalysis ?? FortuneVisualAnalysis(random: random),
        _parser = sectionParser ?? const FortuneSectionParser();

  final Random _rng;
  final FortuneVisualAnalysis _visual;
  final FortuneSectionParser _parser;

  FortuneReadingResult generate(
    FortuneTypeEntity type, {
    String? userInput,
    bool? yesNoChoice,
    String? imageHint,
  }) {
    final imageUrl = _visual.coverUrlFor(type);
    final visualAnalysis = _visual.analyze(type, userImageHint: imageHint);
    final seed = DateTime.now().millisecondsSinceEpoch + _rng.nextInt(9999);

    if (type.isDaily) {
      return _dailyResult(type, imageUrl, visualAnalysis);
    }

    final sections = _buildSections(type, userInput, yesNoChoice, seed);
    final detail = sections.map((s) => '${s.title}\n${s.body}').join('\n\n');
    final summary = sections.first.body.length > 120
        ? '${sections.first.body.substring(0, 117)}…'
        : sections.first.body;

    return FortuneReadingResult(
      type: type,
      summary: summary,
      detail: detail,
      sections: sections,
      imageUrl: imageUrl,
      visualAnalysis: visualAnalysis,
      luckyNumber: 1 + _rng.nextInt(99),
      luckyColor: ['Mor', 'Pembe', 'Altın', 'Turkuaz', 'Mavi'][_rng.nextInt(5)],
    );
  }

  FortuneReadingResult enrichFromApiText({
    required FortuneTypeEntity type,
    required String text,
    String? summary,
    String? recordId,
    int? luckyNumber,
    String? luckyColor,
    String? imageUrl,
    String? imageHint,
  }) {
    final visualAnalysis = _visual.analyze(type, userImageHint: imageHint);
    final parsed = _parser.parse(text);
    final sections = _parser.ensureSections(
      parsed: parsed,
      fallbackDetail: text,
    );
    final resolvedSummary = summary?.trim().isNotEmpty == true
        ? summary!.trim()
        : (sections.isNotEmpty
            ? (sections.first.body.length > 120
                ? '${sections.first.body.substring(0, 117)}…'
                : sections.first.body)
            : (text.length > 120 ? '${text.substring(0, 117)}…' : text));

    return FortuneReadingResult(
      type: type,
      summary: resolvedSummary,
      detail: text,
      sections: sections,
      imageUrl: imageUrl ?? _visual.coverUrlFor(type),
      visualAnalysis: visualAnalysis,
      luckyNumber: luckyNumber,
      luckyColor: luckyColor,
      recordId: recordId,
    );
  }

  FortuneReadingResult _dailyResult(
    FortuneTypeEntity type,
    String imageUrl,
    String visualAnalysis,
  ) {
    final sections = _buildSections(type, null, null, DateTime.now().day);
    final detail = sections.map((s) => '${s.title}\n${s.body}').join('\n\n');
    return FortuneReadingResult(
      type: type,
      summary: 'Enerjin yükseliyor; doğru zamandasın.',
      detail: detail,
      sections: sections,
      imageUrl: imageUrl,
      visualAnalysis: visualAnalysis,
      luckyNumber: 7 + DateTime.now().day % 23,
      luckyColor: const ['Mor', 'Pembe', 'Altın', 'Turkuaz', 'Mavi'][
          DateTime.now().weekday % 5],
    );
  }

  List<FortuneReadingSection> _buildSections(
    FortuneTypeEntity type,
    String? userInput,
    bool? yesNo,
    int seed,
  ) {
    final extra = (userInput != null && userInput.trim().isNotEmpty)
        ? ' Paylaştığın not: «${userInput.trim()}».'
        : '';
    final name = type.title;
    final tone = _tones[seed % _tones.length];
    final opener = _openers[seed % _openers.length];

    String bodyFor(String key) {
      return switch (key) {
        FortuneSectionKeys.general =>
          '$opener $name enerjisi bugün $tone bir frekans taşıyor. '
          'İç dünyanda biriken duygular yüzeye çıkmaya hazır; evren seni '
          'doğru zamanda doğru kapıya yönlendiriyor. Kendine güven, sezgilerin '
          'güçlü.$extra',
        FortuneSectionKeys.love =>
          'Aşk alanında kalbin daha açık ve seçici. Eski yaralar iyileşme '
          'evresinde; yeni bir enerji yakın çevrende beliriyor. İlişkide '
          'olanlar için iletişim anahtar; bekleyenler için beklenmedik bir '
          'mesaj veya karşılaşma mümkün.',
        FortuneSectionKeys.career =>
          'İş ve kariyer hattında disiplinli adımlar öne çıkıyor. '
          'Uzun süredir ertelediğin bir proje veya görüşme için uygun '
          'pencere açılıyor. Yeteneklerini göstermekten çekinme; üstlerin '
          'veya iş ortaklarının dikkatini çekebilirsin.',
        FortuneSectionKeys.money =>
          'Para enerjisi dengeli ama hareketli. Küçük harcamalarda dikkatli '
          'ol; beklenmedik bir gelir kapısı veya tasarruf fırsatı gündeme '
          'gelebilir. Yatırım veya borç konularında acele etme, verileri '
          'okuyarak ilerle.',
        FortuneSectionKeys.future =>
          'Yakın gelecekte yolculuk, taşınma veya yeni bir rutin gündeme '
          'gelebilir. Üç hafta içinde haber veren bir gelişme seni '
          'heyecanlandıracak. Sabırlı kal; zamanlama senin lehine işliyor.',
        FortuneSectionKeys.advice =>
          yesNo != null
              ? (yesNo
                  ? 'Evren «evet» diyor: fırsatı değerlendir ama kalbini '
                    'dinleyerek hareket et. ${FortuneCatalog.tagline}'
                  : 'Evren «bekle» diyor: acele karar verme. '
                    '${FortuneCatalog.tagline}')
              : 'Bugün kendine zaman ayır; meditasyon veya kısa bir yürüyüş '
                'zihnini berraklaştırır. ${FortuneCatalog.tagline} '
                'İç huzurunu koru; evren seninle.',
        _ => '$name yorumun kişisel enerjine göre hazırlandı.$extra',
      };
    }

    return [
      for (var i = 0; i < FortuneSectionKeys.ordered.length; i++)
        FortuneReadingSection(
          key: FortuneSectionKeys.ordered[i],
          title: FortuneSectionKeys.titles[FortuneSectionKeys.ordered[i]]!,
          body: bodyFor(FortuneSectionKeys.ordered[i]),
          delaySeconds: i + 1,
        ),
    ];
  }

  static const _tones = [
    'güçlü ve dönüştürücü',
    'yumuşak ama derin',
    'parlak ve umut dolu',
    'sakin ve bilge',
    'dinamik ve cesur',
  ];

  static const _openers = [
    'Kozmik titreşimler söylüyor ki,',
    'Semboller senin için fısıldıyor:',
    'Evrenin mesajı net:',
    'Bu açılışta görünen enerji,',
    'Kader çizgilerin bugün şunu işaret ediyor:',
  ];
}
