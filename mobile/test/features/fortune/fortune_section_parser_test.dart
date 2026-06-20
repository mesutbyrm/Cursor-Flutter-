import 'package:canlifal_social/features/fortune/domain/entities/fortune_reading_section.dart';
import 'package:canlifal_social/features/fortune/presentation/services/fortune_section_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = FortuneSectionParser();

  test('parse extracts six markdown sections', () {
    const raw = '''
Genel Enerji
Bugün enerjin yükseliyor ve iç sesin güçleniyor.

Aşk Hayatı
Kalbin açık; yakın çevrende sıcak bir haber alabilirsin.

İş ve Kariyer
Disiplinli adımlar öne çıkıyor; hedeflerine odaklan.

Para Durumu
Küçük harcamalarda dikkatli ol; tasarruf fırsatı gelebilir.

Yakın Gelecek
Üç hafta içinde heyecan verici bir gelişme seni bekliyor.

Tavsiye
Kendine zaman ayır; meditasyon zihnini berraklaştırır.
''';

    final sections = parser.parse(raw);
    expect(sections.length, 6);
    expect(sections.first.key, FortuneSectionKeys.general);
    expect(sections.last.key, FortuneSectionKeys.advice);
  });

  test('ensureSections assigns stagger delays', () {
    final sections = parser.ensureSections(
      parsed: const [],
      fallbackDetail: 'Cümle bir. Cümle iki. Cümle üç. Cümle dört. '
          'Cümle beş. Cümle altı. Cümle yedi. Cümle sekiz.',
    );
    expect(sections.length, greaterThanOrEqualTo(4));
    expect(sections.first.delaySeconds, 1);
  });
}
