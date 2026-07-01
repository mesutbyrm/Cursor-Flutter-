import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/dio_provider.dart';
import '../providers/shorts_providers.dart';
import '../studio/short_studio_providers.dart';

enum ShortStudioMode { normal, duet, remix, liveClip, videoReply }

/// Stüdyo açılış parametreleri (`/shorts/upload?...`).
class ShortStudioLaunchParams {
  const ShortStudioLaunchParams({
    this.mode = ShortStudioMode.normal,
    this.sourceVideoId,
    this.liveClipId,
    this.liveClipTitle,
    this.sessionId,
  });

  final ShortStudioMode mode;
  final String? sourceVideoId;
  final String? liveClipId;
  final String? liveClipTitle;
  final String? sessionId;

  static ShortStudioLaunchParams fromUri(Uri uri) {
    final duet = uri.queryParameters['duetOfId'];
    final remix = uri.queryParameters['remixOfId'];
    final clip = uri.queryParameters['liveClipId'];
    final clipTitle = uri.queryParameters['liveClipTitle'];
    final reply = uri.queryParameters['replyToVideoId'];
    final session = uri.queryParameters['sessionId'];

    if (reply != null && reply.isNotEmpty) {
      return ShortStudioLaunchParams(
        mode: ShortStudioMode.videoReply,
        sourceVideoId: reply,
      );
    }
    if (duet != null && duet.isNotEmpty) {
      return ShortStudioLaunchParams(
        mode: ShortStudioMode.duet,
        sourceVideoId: duet,
      );
    }
    if (remix != null && remix.isNotEmpty) {
      return ShortStudioLaunchParams(
        mode: ShortStudioMode.remix,
        sourceVideoId: remix,
      );
    }
    if (clip != null && clip.isNotEmpty) {
      return ShortStudioLaunchParams(
        mode: ShortStudioMode.liveClip,
        liveClipId: clip,
        liveClipTitle: clipTitle,
        sessionId: session,
      );
    }
    return const ShortStudioLaunchParams();
  }

  String get routeQuery {
    return switch (mode) {
      ShortStudioMode.duet =>
        '?duetOfId=${Uri.encodeComponent(sourceVideoId ?? '')}',
      ShortStudioMode.remix =>
        '?remixOfId=${Uri.encodeComponent(sourceVideoId ?? '')}',
      ShortStudioMode.videoReply =>
        '?replyToVideoId=${Uri.encodeComponent(sourceVideoId ?? '')}',
      ShortStudioMode.liveClip =>
        '?liveClipId=${Uri.encodeComponent(liveClipId ?? '')}'
        '${liveClipTitle != null ? '&liveClipTitle=${Uri.encodeComponent(liveClipTitle!)}' : ''}'
        '${sessionId != null ? '&sessionId=${Uri.encodeComponent(sessionId!)}' : ''}',
      ShortStudioMode.normal => '',
    };
  }
}

void openShortStudio(
  GoRouter router, {
  ShortStudioMode mode = ShortStudioMode.normal,
  String? sourceVideoId,
  String? liveClipId,
  String? liveClipTitle,
  String? sessionId,
}) {
  final params = ShortStudioLaunchParams(
    mode: mode,
    sourceVideoId: sourceVideoId,
    liveClipId: liveClipId,
    liveClipTitle: liveClipTitle,
    sessionId: sessionId,
  );
  router.push('/shorts/upload${params.routeQuery}');
}

Future<void> applyStudioLaunchParams(
  WidgetRef ref,
  ShortStudioLaunchParams params, {
  void Function(String message)? onStatus,
}) async {
  if (params.mode == ShortStudioMode.normal) return;

  ref.read(shortUploadDraftProvider.notifier).reset();

  if (params.mode == ShortStudioMode.liveClip) {
    final title = params.liveClipTitle?.trim();
    ref.read(shortUploadDraftProvider.notifier).patch(
          (d) => d.copyWith(
            sourceLiveClipId: params.liveClipId,
            description: title != null && title.isNotEmpty
                ? '📺 Canlı fal klibi — $title'
                : '📺 Canlı fal klibi',
          ),
        );
    final clipId = params.liveClipId;
    if (clipId == null || clipId.isEmpty) return;
    try {
      onStatus?.call('Klip hazırlanıyor…');
      final clip = await ref.read(shortsRepositoryProvider).fetchLiveClip(
            liveClipId: clipId,
            sessionId: params.sessionId,
          );
      final localPath = await _downloadClip(ref, clip.clipUrl);
      if (localPath != null) {
        ref.read(shortUploadDraftProvider.notifier).patch(
              (d) => d.copyWith(sourcePath: localPath),
            );
        onStatus?.call('Klip indirildi.');
      }
    } catch (_) {
      onStatus?.call('Klip API kullanılamadı — galeriden seçin.');
    }
    return;
  }

  final videoId = params.sourceVideoId;
  if (videoId == null || videoId.isEmpty) return;

  try {
    final video = await ref.read(shortsRepositoryProvider).fetchVideo(videoId);
    if (params.mode == ShortStudioMode.duet) {
      ref.read(shortUploadDraftProvider.notifier).patch(
            (d) => d.copyWith(
              duetOfId: videoId,
              sourceVideoTitle: video.author?.label ?? video.description,
            ),
          );
    } else if (params.mode == ShortStudioMode.remix) {
      ref.read(shortUploadDraftProvider.notifier).patch(
            (d) => d.copyWith(
              remixOfId: videoId,
              musicId: video.music?.id,
              musicTitle: video.music?.title,
              sourceVideoTitle: video.music?.title ?? video.author?.label,
              description: video.music != null
                  ? '🎵 ${video.music!.title}'
                  : d.description,
            ),
          );
    } else if (params.mode == ShortStudioMode.videoReply) {
      ref.read(shortUploadDraftProvider.notifier).patch(
            (d) => d.copyWith(
              replyToVideoId: videoId,
              sourceVideoTitle: video.author?.label ?? video.description,
              description: '↩️ @${video.author?.username ?? 'video'} yanıtı',
            ),
          );
    }
  } catch (_) {}
}

Future<String?> _downloadClip(WidgetRef ref, String url) async {
  if (url.isEmpty) return null;
  try {
    final dio = ref.read(dioProvider);
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/live_clip_${DateTime.now().millisecondsSinceEpoch}.mp4';
    await dio.download(url, path);
    if (await File(path).exists()) return path;
  } catch (_) {}
  return null;
}
