import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/short_upload_draft.dart';
import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_providers.dart';
import '../studio/short_studio_providers.dart';

enum ShortStudioMode { normal, duet, remix, liveClip }

/// Stüdyo açılış parametreleri (`/shorts/upload?...`).
class ShortStudioLaunchParams {
  const ShortStudioLaunchParams({
    this.mode = ShortStudioMode.normal,
    this.sourceVideoId,
    this.liveClipId,
    this.liveClipTitle,
  });

  final ShortStudioMode mode;
  final String? sourceVideoId;
  final String? liveClipId;
  final String? liveClipTitle;

  static ShortStudioLaunchParams fromUri(Uri uri) {
    final duet = uri.queryParameters['duetOfId'];
    final remix = uri.queryParameters['remixOfId'];
    final clip = uri.queryParameters['liveClipId'];
    final clipTitle = uri.queryParameters['liveClipTitle'];

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
      ShortStudioMode.liveClip =>
        '?liveClipId=${Uri.encodeComponent(liveClipId ?? '')}'
        '${liveClipTitle != null ? '&liveClipTitle=${Uri.encodeComponent(liveClipTitle!)}' : ''}',
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
}) {
  final params = ShortStudioLaunchParams(
    mode: mode,
    sourceVideoId: sourceVideoId,
    liveClipId: liveClipId,
    liveClipTitle: liveClipTitle,
  );
  router.push('/shorts/upload${params.routeQuery}');
}

Future<void> applyStudioLaunchParams(
  WidgetRef ref,
  ShortStudioLaunchParams params,
) async {
  if (params.mode == ShortStudioMode.normal) return;

  ref.read(shortUploadDraftProvider.notifier).reset();

  if (params.mode == ShortStudioMode.liveClip) {
    final title = params.liveClipTitle?.trim();
    ref.read(shortUploadDraftProvider.notifier).patch(
          (d) => d.copyWith(
            sourceLiveClipId: params.liveClipId,
            description: title != null && title.isNotEmpty
                ? '📺 Canlı yayın klibi — $title'
                : '📺 Canlı yayın klibi',
          ),
        );
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
    }
  } catch (_) {}
}
