import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'voice_room_music_pipeline_log.dart';

/// Android ExoPlayer ile URL doğrudan test (just_audio alt katmanı).
class ExoPlayerProbe {
  ExoPlayerProbe._();

  static const _channel = MethodChannel('com.mesutbyrm.canlifal/exo_probe');

  static Future<void> testUrlIfAndroid(String url) async {
    if (url.trim().isEmpty) return;
    if (defaultTargetPlatform != TargetPlatform.android) {
      VoiceRoomMusicPipelineLog.exoProbeResult(
        url: url,
        ok: false,
        errorMessage: 'skipped_non_android',
      );
      return;
    }
    final started = DateTime.now();
    try {
      final raw = await _channel.invokeMethod<dynamic>('probeUrl', {
        'url': url,
      });
      final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      VoiceRoomMusicPipelineLog.exoProbeResult(
        url: url,
        ok: map['ok'] == true,
        errorCode: map['errorCode']?.toString(),
        errorMessage: map['error']?.toString(),
        elapsedMs: DateTime.now().difference(started).inMilliseconds,
      );
    } catch (e, st) {
      VoiceRoomMusicPipelineLog.exoProbeResult(
        url: url,
        ok: false,
        errorMessage: '$e',
        elapsedMs: DateTime.now().difference(started).inMilliseconds,
      );
      VoiceRoomMusicPipelineLog.justAudioError(
        e,
        st,
        phase: 'exo_probe_channel',
        url: url,
      );
    }
  }
}
