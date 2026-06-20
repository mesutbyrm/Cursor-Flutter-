import 'dart:math';

import '../../domain/entities/fortune_type_entity.dart';
import '../data/fortune_type_images.dart';

/// Fal kapak görselinden türetilen sembolik analiz metni.
class FortuneVisualAnalysis {
  FortuneVisualAnalysis({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  String analyze(FortuneTypeEntity type, {String? userImageHint}) {
    final slug = type.slug;
    final palette = _paletteFor(slug);
    final symbols = _symbolsFor(slug);
    final energy = _energies[_rng.nextInt(_energies.length)];
    final symbol = symbols[_rng.nextInt(symbols.length)];
    final color = palette[_rng.nextInt(palette.length)];

    final imageNote = userImageHint != null && userImageHint.trim().isNotEmpty
        ? ' Yüklediğin görselde ${userImageHint.trim()} izleri belirgin.'
        : '';

    return switch (slug) {
      'tarot' =>
        'Kart sembollerinde $symbol öne çıkıyor; $color tonları '
        '$energy bir enerji alanı oluşturuyor.$imageNote '
        'Sembolik düzlemde geçmiş–şimdi–gelecek hattı senin adına açılıyor.',
      'kahve-fali' =>
        'Fincan desenlerinde $symbol şekli ve $color lekeleri '
        'yoğunlaşmış; duman çizgileri $energy bir akış gösteriyor.$imageNote '
        'Telve yolları yakın dönemde beklenmedik bir habere işaret ediyor.',
      'ruya-tabiri' =>
        'Ay ışığı altında $symbol motifi ve $color bulut katmanları '
        'bilinçaltında $energy bir titreşim bırakmış.$imageNote '
        'Rüya sembolleri gerçek hayattaki bir dönüşümü mühürlüyor.',
      'el-fali' =>
        'Avuç çizgilerinde $symbol hattı ve $color enerji alanı '
        'yaşam çizgisiyle kesişiyor; $energy bir potansiyel taşıyor.$imageNote '
        'Kalp ve kader çizgileri senin için uyumlu bir ritimde.',
      'yildiz-haritasi' =>
        'Zodyak çemberinde $symbol konumu ve $color galaksi tonları '
        '$energy bir göksel etki yaratıyor.$imageNote '
        'Burç haritan bugün seni cesur adımlara çağırıyor.',
      _ =>
        'Görselde $symbol sembolü ve $color ışık oyunları '
        '$energy bir aura oluşturuyor.$imageNote '
        '${type.title} enerjisi kişisel yorumuna özel olarak işlendi.',
    };
  }

  String coverUrlFor(FortuneTypeEntity type) =>
      FortuneTypeImages.urlFor(type.slug, width: 1200);

  static const _energies = [
    'güçlü',
    'yumuşak ama derin',
    'dönüştürücü',
    'koruyucu',
    'yükselen',
  ];

  List<String> _symbolsFor(String slug) => switch (slug) {
        'tarot' => ['Güneş', 'Ay', 'Yıldız', 'Kule', 'Büyücü', 'İmparatoriçe'],
        'kahve-fali' => ['kuş', 'yol', 'kalp', 'ağaç', 'halka', 'kapı'],
        'ruya-tabiri' => ['su', 'uçuş', 'kapı', 'ay', 'köprü', 'ışık'],
        'el-fali' => ['yaşam', 'kalp', 'kader', 'sezgi', 'venüs', 'mars'],
        'yildiz-haritasi' => ['koç', 'aslan', 'yay', 'balık', 'ikizler', 'terazi'],
        _ => ['yıldız', 'spiral', 'halka', 'ok', 'çiçek', 'kristal'],
      };

  List<String> _paletteFor(String slug) => switch (slug) {
        'tarot' => ['mor-altın', 'gece laciverti', 'ametist'],
        'kahve-fali' => ['karamel', 'bakır', 'espresso'],
        'ruya-tabiri' => ['gümüş-mavi', 'lavanta', 'gece moru'],
        'el-fali' => ['turkuaz', 'pembe-altın', 'kozmik yeşil'],
        'yildiz-haritasi' => ['galaksi mavisi', 'altın', 'nebula moru'],
        _ => ['mor', 'altın', 'turkuaz'],
      };
}
