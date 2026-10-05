import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Oda arka planı için 100 renk: 1 gri tonlama satırı + 9 satır × 10 ton.
List<Color> voiceRoomBackgroundColors() {
  final colors = <Color>[];
  // Satır 0: beyazdan siyaha 10 gri ton.
  for (var i = 0; i < 10; i++) {
    final v = (255 - (i * 255 / 9)).round();
    colors.add(Color.fromARGB(255, v, v, v));
  }
  // Satır 1..9: 10 ton (0°..324°) × 9 koyuluk.
  for (var row = 0; row < 9; row++) {
    final lightness = 0.22 + row * 0.065;
    for (var col = 0; col < 10; col++) {
      colors.add(
        HSLColor.fromAHSL(1, col * 36.0, 0.72, lightness.clamp(0.0, 1.0))
            .toColor(),
      );
    }
  }
  return colors;
}

/// Seçilen rengi dikey, hafif koyulaşan bir PNG'ye çevirir (sunucuya yüklenip
/// oda arka planı olarak kaydedilir; web ve mobilde aynı görünür).
Future<File> renderVoiceRoomBackgroundPng(Color color) async {
  const w = 540;
  const h = 960;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final hsl = HSLColor.fromColor(color);
  final darker = hsl
      .withLightness((hsl.lightness * 0.55).clamp(0.0, 1.0))
      .toColor();
  final paint = Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      Offset(0, h.toDouble()),
      [color, darker],
    );
  canvas.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), paint);
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File(
    '${Directory.systemTemp.path}/room_bg_${color.toARGB32()}.png',
  );
  await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
  return file;
}
