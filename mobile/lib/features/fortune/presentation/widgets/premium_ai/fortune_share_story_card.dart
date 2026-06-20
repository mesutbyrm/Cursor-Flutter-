import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/fortune_type_entity.dart';
import '../fortune_type_network_image.dart';

/// Instagram Story kalitesinde fal paylaşım kartı (9:16).
class FortuneShareStoryCard extends StatelessWidget {
  const FortuneShareStoryCard({
    super.key,
    required this.result,
    required this.username,
  });

  final FortuneReadingResult result;
  final String username;

  static const storyWidth = 360.0;
  static const storyHeight = 640.0;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMMM yyyy', 'tr_TR').format(DateTime.now());
    final type = result.type;

    return SizedBox(
      width: storyWidth,
      height: storyHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FortuneTypeNetworkImage(
              slug: type.slug,
              accent: type.accent,
              emoji: type.emoji,
              borderRadius: 0,
              imageWidth: 1080,
              heroTag: 'share-${type.slug}',
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.55),
                    const Color(0xFF0A0118).withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: type.accent.withValues(alpha: 0.3),
                        child: Text(type.emoji, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              date,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: type.accent.withValues(alpha: 0.35),
                          border: Border.all(color: type.accent.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          type.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '✨ AI Fal Özeti',
                    style: TextStyle(
                      color: type.accent.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    result.summary,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('🔮', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        'canlifal.com',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paylaşım kartını PNG olarak yakalar ve paylaşır.
class FortuneShareImageService {
  FortuneShareImageService._();

  static Future<void> shareStoryImage({
    required GlobalKey repaintKey,
    required FortuneReadingResult result,
    required String username,
  }) async {
    final bytes = await _capture(repaintKey);
    if (bytes == null) {
      await SharePlus.instance.share(
        ShareParams(
          text: '${result.type.title} — ${result.summary}\n\ncanlifal.com',
          subject: 'Canlifal Fal',
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/canlifal_fortune_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: '${result.type.title} — ${result.summary}',
        subject: 'Canlifal Fal',
      ),
    );
  }

  static Future<Uint8List?> _capture(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }
}
