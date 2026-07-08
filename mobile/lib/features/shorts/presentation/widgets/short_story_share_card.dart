import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../domain/entities/short_video_entity.dart';
import '../pages/shorts_feed_page.dart';

/// Hikâye paylaşım kartı — 9:16 önizleme + PNG dışa aktarma.
class ShortStoryShareCard extends StatelessWidget {
  const ShortStoryShareCard({
    super.key,
    required this.video,
    required this.captureKey,
  });

  final ShortVideoEntity video;
  final GlobalKey captureKey;

  @override
  Widget build(BuildContext context) {
    final author = video.author?.label ?? video.author?.username ?? 'Canlifal';
    final desc = video.description?.trim();

    return RepaintBoundary(
      key: captureKey,
      child: Container(
        width: 270,
        height: 480,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1035), Color(0xFF0D0D12)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CanlifalNetworkImage(
                  url: video.thumbnailUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  thumbnailWidth: 540,
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  const Text(
                    'Canlifal Shorts',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '@$author',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  if (desc != null && desc.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    shortVideoShareUrl(video.id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
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

Future<String?> renderShortStoryShareImage(
  GlobalKey captureKey, {
  Dio? dio,
}) async {
  final boundary = captureKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) return null;

  final image = await boundary.toImage(pixelRatio: 3);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return null;

  final dir = await getTemporaryDirectory();
  final path =
      '${dir.path}/short_story_${DateTime.now().millisecondsSinceEpoch}.png';
  await File(path).writeAsBytes(byteData.buffer.asUint8List());
  return path;
}

Future<String?> downloadThumbnailForStory(
  ShortVideoEntity video,
  Dio dio,
) async {
  final url = video.thumbnailUrl;
  if (url == null || url.isEmpty) return null;
  try {
    final res = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = res.data;
    if (bytes == null || bytes.isEmpty) return null;
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/short_thumb_${video.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(path).writeAsBytes(Uint8List.fromList(bytes));
    return path;
  } catch (_) {
    return null;
  }
}
