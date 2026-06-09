import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../data/youtube_stream_resolver.dart';
import '../audio/voice_room_dj_stream_loader.dart';
import '../audio/voice_room_music_audio_session.dart';

/// Oda arka plan müziği — DJ API `musicUrl` ile senkron (web iframe yerine stream).
class VoiceRoomDjPlayer {
  VoiceRoomDjPlayer(this._resolver, this._streamLoader)
      : _player = AudioPlayer(playerId: 'voice_room_dj') {
    _player.setReleaseMode(ReleaseMode.stop);
    _initFuture = _initPlayer();
    _player.onPlayerComplete.listen((_) {
      onTrackComplete?.call();
    });
    _player.onDurationChanged.listen((d) {
      playback.value = VoiceRoomDjPlayback(
        position: playback.value.position,
        duration: d,
        playing: playback.value.playing,
      );
    });
    _player.onPositionChanged.listen((p) {
      playback.value = VoiceRoomDjPlayback(
        position: p,
        duration: playback.value.duration,
        playing: playback.value.playing,
      );
    });
    _player.onPlayerStateChanged.listen((s) {
      playback.value = VoiceRoomDjPlayback(
        position: playback.value.position,
        duration: playback.value.duration,
        playing: s == PlayerState.playing,
      );
    });
  }

  final YoutubeStreamResolver _resolver;
  final VoiceRoomDjStreamLoader _streamLoader;
  final AudioPlayer _player;
  late final Future<void> _initFuture;
  final ValueNotifier<VoiceRoomDjPlayback> playback =
      ValueNotifier(const VoiceRoomDjPlayback());
  String? _currentKey;
  void Function()? onTrackComplete;

  Future<void> _initPlayer() async {
    await VoiceRoomMusicAudioSession.ensureConfigured();
    try {
      await _player.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
      await _player.setVolume(1.0);
    } catch (e) {
      debugPrint('DJ audio context: $e');
    }
  }

  Future<bool> sync({
    String? musicUrl,
    String? fallbackYoutubeUrl,
    required bool playing,
    bool muted = false,
  }) async {
    await _initFuture;
    if (muted || !playing || musicUrl == null || musicUrl.isEmpty) {
      await stop();
      return false;
    }

    await VoiceRoomMusicAudioSession.ensureConfigured();

    final candidates = <String>[
      musicUrl,
      if (fallbackYoutubeUrl != null &&
          fallbackYoutubeUrl.isNotEmpty &&
          fallbackYoutubeUrl != musicUrl)
        fallbackYoutubeUrl,
    ];

    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        for (final c in candidates) {
          _resolver.invalidate(c);
          _streamLoader.invalidate(c);
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }

      for (final candidate in candidates) {
        final resolved = await _resolveSource(candidate);
        if (resolved == null || resolved.isEmpty) continue;

        final playable = await _streamLoader.preparePlaybackSource(resolved);
        if (playable == null || playable.isEmpty) continue;

        if (_currentKey == playable && _player.state == PlayerState.playing) {
          return true;
        }

        try {
          await VoiceRoomMusicAudioSession.activateForPlayback();
          _currentKey = playable;
          if (_player.state == PlayerState.playing) {
            await _player.stop();
          }
          await _player.setVolume(1.0);

          final source = playable.startsWith('/')
              ? DeviceFileSource(playable, mimeType: _mimeForPath(playable))
              : UrlSource(
                  playable,
                  mimeType: _mimeForUrl(playable),
                );

          await _player.play(source);
          await Future<void>.delayed(const Duration(milliseconds: 320));
          if (_player.state == PlayerState.playing) {
            playback.value = VoiceRoomDjPlayback(
              position: Duration.zero,
              duration: playback.value.duration,
              playing: true,
            );
            debugPrint('DJ play ok: $playable');
            return true;
          }
        } catch (e) {
          debugPrint('DJ play error ($candidate): $e');
          _currentKey = null;
        }
      }
    }

    debugPrint('DJ: oynatılamadı — musicUrl=$musicUrl');
    return false;
  }

  Future<String?> _resolveSource(String musicUrl) async {
    return _resolver.resolvePlayableUrl(musicUrl);
  }

  static String? _mimeForUrl(String url) {
    final u = url.toLowerCase();
    if (u.contains('mime=audio%2Fwebm') || u.contains('audio/webm')) {
      return 'audio/webm';
    }
    if (u.contains('mime=audio%2Fmp4') ||
        u.contains('audio/mp4') ||
        u.endsWith('.m4a')) {
      return 'audio/mp4';
    }
    if (u.endsWith('.mp3')) return 'audio/mpeg';
    if (u.endsWith('.opus')) return 'audio/opus';
    return null;
  }

  static String? _mimeForPath(String path) {
    if (path.endsWith('.mp3')) return 'audio/mpeg';
    if (path.endsWith('.m4a')) return 'audio/mp4';
    if (path.endsWith('.webm')) return 'audio/webm';
    return 'audio/mp4';
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      playback.value = VoiceRoomDjPlayback(
        position: playback.value.position,
        duration: playback.value.duration,
        playing: false,
      );
    } catch (e) {
      debugPrint('DJ pause: $e');
    }
  }

  Future<void> resume() async {
    if (_currentKey == null) return;
    try {
      await VoiceRoomMusicAudioSession.activateForPlayback();
      await _player.resume();
      playback.value = VoiceRoomDjPlayback(
        position: playback.value.position,
        duration: playback.value.duration,
        playing: true,
      );
    } catch (e) {
      debugPrint('DJ resume: $e');
    }
  }

  Future<void> stop() async {
    _currentKey = null;
    try {
      await _player.stop();
      playback.value = const VoiceRoomDjPlayback();
    } catch (_) {}
  }

  void dispose() {
    onTrackComplete = null;
    playback.dispose();
    _player.dispose();
  }
}

class VoiceRoomDjPlayback {
  const VoiceRoomDjPlayback({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
  });

  final Duration position;
  final Duration duration;
  final bool playing;

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  Duration get remaining {
    if (duration <= position) return Duration.zero;
    return duration - position;
  }
}
