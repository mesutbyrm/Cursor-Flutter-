import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../live/domain/entities/voice_room_entity.dart';

/// Oda türüne göre arka plan setleri: her biri 50 tasarım.
enum VoiceRoomBgTier { free, paid, vip }

extension VoiceRoomBgTierX on VoiceRoomBgTier {
  String get label => switch (this) {
        VoiceRoomBgTier.free => 'Ücretsiz',
        VoiceRoomBgTier.paid => 'Ücretli',
        VoiceRoomBgTier.vip => 'VIP',
      };

  String get roomLabel => switch (this) {
        VoiceRoomBgTier.free => 'ücretsiz',
        VoiceRoomBgTier.paid => 'ücretli',
        VoiceRoomBgTier.vip => 'VIP',
      };
}

/// Odanın türü: `VIP` → vip, `NORMAL` (ücretli) → paid, aksi halde ücretsiz.
VoiceRoomBgTier voiceRoomBgTierFor(VoiceRoomEntity room) {
  final t = (room.roomType ?? '').trim().toUpperCase();
  if (room.isVip == true || t == 'VIP') return VoiceRoomBgTier.vip;
  if (t == 'NORMAL' || t == 'PAID' || t == 'ÜCRETLİ') {
    return VoiceRoomBgTier.paid;
  }
  return VoiceRoomBgTier.free;
}

/// [tier] seti bu odada kullanılabilir mi (üst tür alt türün setlerini de açar).
bool voiceRoomBgTierAllowed(
  VoiceRoomBgTier roomTier,
  VoiceRoomBgTier setTier, {
  bool isSiteAdmin = false,
}) =>
    isSiteAdmin || setTier.index <= roomTier.index;

class VoiceRoomBgDesign {
  const VoiceRoomBgDesign({
    required this.id,
    required this.tier,
    required this.index,
    required this.name,
    required this.a,
    required this.b,
    required this.accent,
    required this.style,
    this.watermark = false,
  });

  final String id;
  final VoiceRoomBgTier tier;
  final int index;
  final String name;
  final Color a;
  final Color b;
  final Color accent;
  final int style;
  final bool watermark;
}

/// Varsayılan GirLive arka planı: koyu kozmik + sohbet bölgesinde şeffaf
/// «GirLive Sesli Odaları» yazısı.
const voiceRoomBgDefaultDesign = VoiceRoomBgDesign(
  id: 'default-girlive',
  tier: VoiceRoomBgTier.free,
  index: 0,
  name: 'Varsayılan',
  a: Color(0xFF1B0B3A),
  b: Color(0xFF0A0418),
  accent: Color(0xFF8B5CF6),
  style: 1,
  watermark: true,
);

List<VoiceRoomBgDesign>? _cacheFree, _cachePaid, _cacheVip;

/// [tier] için 50 tasarım (deterministik).
List<VoiceRoomBgDesign> voiceRoomBgDesigns(VoiceRoomBgTier tier) {
  switch (tier) {
    case VoiceRoomBgTier.free:
      return _cacheFree ??= _build(tier);
    case VoiceRoomBgTier.paid:
      return _cachePaid ??= _build(tier);
    case VoiceRoomBgTier.vip:
      return _cacheVip ??= _build(tier);
  }
}

List<VoiceRoomBgDesign> _build(VoiceRoomBgTier tier) {
  final prefix = switch (tier) {
    VoiceRoomBgTier.free => 'Gökyüzü',
    VoiceRoomBgTier.paid => 'Aurora',
    VoiceRoomBgTier.vip => 'Altın',
  };
  return List.generate(50, (i) {
    final h1 = (i * 7.2 + switch (tier) {
              VoiceRoomBgTier.free => 0,
              VoiceRoomBgTier.paid => 120,
              VoiceRoomBgTier.vip => 240,
            }) %
        360;
    final h2 = (h1 + 30 + (i % 5) * 22) % 360;
    final sat = switch (tier) {
      VoiceRoomBgTier.free => 0.55,
      VoiceRoomBgTier.paid => 0.68,
      VoiceRoomBgTier.vip => 0.6,
    };
    final light = switch (tier) {
      VoiceRoomBgTier.free => 0.30 + (i % 4) * 0.04,
      VoiceRoomBgTier.paid => 0.24 + (i % 4) * 0.035,
      VoiceRoomBgTier.vip => 0.13 + (i % 4) * 0.025,
    };
    final a = HSLColor.fromAHSL(1, h1, sat, light).toColor();
    final b = HSLColor.fromAHSL(1, h2, sat, (light * 0.55).clamp(0.05, 1))
        .toColor();
    final accent = tier == VoiceRoomBgTier.vip
        ? const Color(0xFFFFC857)
        : HSLColor.fromAHSL(1, (h1 + 180) % 360, 0.85, 0.65).toColor();
    return VoiceRoomBgDesign(
      id: '${tier.name}-${i + 1}',
      tier: tier,
      index: i,
      name: '$prefix ${i + 1}',
      a: a,
      b: b,
      accent: accent,
      style: i % 5,
    );
  });
}

/// Aynı çizici hem küçük önizlemede hem yüklenen PNG'de kullanılır.
void paintVoiceRoomBg(Canvas canvas, Size size, VoiceRoomBgDesign d) {
  final w = size.width;
  final h = size.height;
  final rect = Rect.fromLTWH(0, 0, w, h);
  final rnd = math.Random(d.id.hashCode);

  // Taban degrade (yön stile göre değişir).
  final dir = d.style % 3;
  final from = switch (dir) {
    0 => Offset.zero,
    1 => Offset(w, 0),
    _ => Offset(w / 2, 0),
  };
  final to = switch (dir) {
    0 => Offset(w, h),
    1 => Offset(0, h),
    _ => Offset(w / 2, h),
  };
  canvas.drawRect(
    rect,
    Paint()..shader = ui.Gradient.linear(from, to, [d.a, d.b]),
  );

  // Işık hâlesi.
  final glowCenter = Offset(
    w * (0.2 + rnd.nextDouble() * 0.6),
    h * (0.12 + rnd.nextDouble() * 0.3),
  );
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.radial(
        glowCenter,
        w * (d.style == 1 ? 0.9 : 0.7),
        [d.accent.withValues(alpha: 0.38), d.accent.withValues(alpha: 0)],
      ),
  );

  switch (d.tier) {
    case VoiceRoomBgTier.free:
      if (d.style >= 3) {
        // Yumuşak dalgalar.
        for (var k = 0; k < 3; k++) {
          final p = Path()
            ..moveTo(0, h * (0.55 + k * 0.13))
            ..quadraticBezierTo(
              w * 0.5,
              h * (0.45 + k * 0.13 + 0.06 * (k.isEven ? 1 : -1)),
              w,
              h * (0.58 + k * 0.13),
            )
            ..lineTo(w, h)
            ..lineTo(0, h)
            ..close();
          canvas.drawPath(
            p,
            Paint()..color = Colors.white.withValues(alpha: 0.04 + k * 0.02),
          );
        }
      }
    case VoiceRoomBgTier.paid:
      // Yıldız tozu + ikinci hâle.
      for (var k = 0; k < 70; k++) {
        canvas.drawCircle(
          Offset(rnd.nextDouble() * w, rnd.nextDouble() * h),
          0.5 + rnd.nextDouble() * 1.6,
          Paint()
            ..color =
                Colors.white.withValues(alpha: 0.12 + rnd.nextDouble() * 0.5),
        );
      }
      canvas.drawCircle(
        Offset(w * (0.8 - rnd.nextDouble() * 0.5), h * 0.7),
        w * 0.45,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(w * 0.5, h * 0.7),
            w * 0.45,
            [d.accent.withValues(alpha: 0.18), d.accent.withValues(alpha: 0)],
          ),
      );
    case VoiceRoomBgTier.vip:
      // Elmas kafes + altın parıltılar + ince çerçeve.
      final line = Paint()
        ..color = d.accent.withValues(alpha: 0.10)
        ..strokeWidth = 1;
      const step = 56.0;
      for (var x = -h; x < w + h; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x + h, h), line);
        canvas.drawLine(Offset(x, h), Offset(x + h, 0), line);
      }
      for (var k = 0; k < 46; k++) {
        final o = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h);
        canvas.drawCircle(
          o,
          0.7 + rnd.nextDouble() * 2.0,
          Paint()
            ..color =
                d.accent.withValues(alpha: 0.25 + rnd.nextDouble() * 0.6),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(6), const Radius.circular(18)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(w, h),
            [
              d.accent.withValues(alpha: 0.85),
              d.accent.withValues(alpha: 0.15),
              d.accent.withValues(alpha: 0.85),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
  }

  // Sohbet/koltuk okunurluğu için alt kısım hafif karartılır.
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.5),
        Offset(0, h),
        [const Color(0x00000000), const Color(0x59000000)],
      ),
  );

  if (d.watermark) paintGirLiveWatermark(canvas, size);
}

/// Sohbet bölgesine denk gelen şeffaf «GirLive Sesli Odaları» yazısı.
void paintGirLiveWatermark(Canvas canvas, Size size) {
  final fontSize = size.width * 0.085;
  final tp = TextPainter(
    text: TextSpan(
      children: [
        TextSpan(
          text: 'GirLive\n',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.13),
            fontSize: fontSize * 1.35,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            height: 1.05,
          ),
        ),
        TextSpan(
          text: 'Sesli Odaları',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.11),
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width);
  tp.paint(
    canvas,
    Offset((size.width - tp.width) / 2, size.height * 0.60 - tp.height / 2),
  );
}

class VoiceRoomBgPainter extends CustomPainter {
  const VoiceRoomBgPainter(this.design);

  final VoiceRoomBgDesign design;

  @override
  void paint(Canvas canvas, Size size) => paintVoiceRoomBg(canvas, size, design);

  @override
  bool shouldRepaint(covariant VoiceRoomBgPainter old) => old.design != design;
}

/// Tasarımı sunucuya yüklenecek PNG'ye çevirir (web ve mobilde aynı görünür).
Future<File> renderVoiceRoomBgDesignPng(VoiceRoomBgDesign d) async {
  const w = 405;
  const h = 720;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paintVoiceRoomBg(canvas, const Size(w + 0.0, h + 0.0), d);
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File('${Directory.systemTemp.path}/room_bg_${d.id}.png');
  await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
  return file;
}
