import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../domain/entities/short_explore_entity.dart';
import '../domain/entities/shorts_ai_metadata.dart';

/// İstemci tarafı AI yedekleri — API yoksa veya hata verirse.
class ShortsAiHelper {
  ShortsAiHelper._();

  static Future<List<String>> generateThumbnailCandidates(String videoPath) async {
    if (!await File(videoPath).exists()) return const [];
    final dir = await getTemporaryDirectory();
    final out = <String>[];
    for (final pct in [0.15, 0.45, 0.75]) {
      try {
        final path = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: await _timeMsForPercent(videoPath, pct),
          maxWidth: 720,
          quality: 88,
          thumbnailPath: dir.path,
        );
        if (path != null && path.isNotEmpty) out.add(path);
      } catch (_) {}
    }
    return out;
  }

  static Future<int> _timeMsForPercent(String videoPath, double pct) async {
    // video_thumbnail timeMs — yaklaşık kare; süre bilinmiyorsa sabit aralık.
    return (pct * 12000).round().clamp(100, 14000);
  }

  static ShortsAiMetadata fallbackMetadata(String description) {
    final words = description
        .replaceAll(RegExp(r'[#@]\w+'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 4)
        .take(6)
        .map((w) => w.toLowerCase())
        .toSet()
        .take(5)
        .toList();
    final summary = description.trim().length > 20
        ? '${description.trim().substring(0, description.trim().length.clamp(0, 120))}…'
        : description.trim();
    return ShortsAiMetadata(
      summary: summary.isNotEmpty ? summary : null,
      hashtags: words,
    );
  }

  static String fallbackSubtitles(String description) {
    if (description.trim().isEmpty) {
      return 'WEBVTT\n\n00:00:00.000 --> 00:00:05.000\nCanlifal Shorts';
    }
    final lines = description.trim().split('\n').take(8);
    final buf = StringBuffer('WEBVTT\n\n');
    var sec = 0;
    for (final line in lines) {
      final start = _fmt(sec);
      sec += 3;
      final end = _fmt(sec);
      buf.writeln('$start --> $end');
      buf.writeln(line.trim());
      buf.writeln();
    }
    return buf.toString();
  }

  static String _fmt(int sec) {
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s.000';
  }

  static List<ShortMusicEntity> pickLocalMusicFallback(
    List<ShortMusicEntity> catalog,
    List<String> hashtags,
  ) {
    if (catalog.isEmpty) return const [];
    if (hashtags.isEmpty) return catalog.take(5).toList();
    final tag = hashtags.first.toLowerCase();
    final matched = catalog.where((m) {
      final hay = '${m.title} ${m.artist ?? ''}'.toLowerCase();
      return hay.contains(tag);
    }).toList();
    if (matched.isNotEmpty) return matched.take(5).toList();
    return catalog.take(5).toList();
  }
}
