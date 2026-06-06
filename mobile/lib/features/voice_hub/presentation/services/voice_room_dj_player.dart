import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../data/youtube_stream_resolver.dart';
import '../audio/voice_room_music_audio_session.dart';

/// Oda arka plan müziği — DJ API `musicUrl` ile senkron (web iframe yerine stream URL).
class VoiceRoomDjPlayer {
  VoiceRoomDjPlayer(this._resolver)
      : _player = AudioPlayer(playerId: 'voice_room_dj') {
    _player.setReleaseMode(ReleaseMode.stop);
    unawaited(_initPlayer());
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
  final AudioPlayer _player;
  final ValueNotifier<VoiceRoomDjPlayback> playback =
      ValueNotifier(const VoiceRoomDjPlayback());
  String? _currentUrl;
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

  /// Oynatma başarılıysa `true` döner.
  Future<bool> sync({
    String? musicUrl,
    String? fallbackYoutubeUrl,
    required bool playing,
    bool muted = false,
  }) async {
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

    for (final candidate in candidates) {
      final source = await _resolveSource(candidate);
      debugPrint(
        'DJ sync: candidate=$candidate streamUrl=$source '
        'playState=$playing playerState=${_player.state}',
      );
      if (source == null || source.isEmpty) continue;

      final alreadyPlaying =
          _currentUrl == source && _player.state == PlayerState.playing;
      if (alreadyPlaying) return true;

      try {
        await VoiceRoomMusicAudioSession.activateForPlayback();
        _currentUrl = source;
        await _player.stop();
        await _player.setVolume(1.0);
        await _player.play(UrlSource(source));
        playback.value = VoiceRoomDjPlayback(
          position: Duration.zero,
          duration: playback.value.duration,
          playing: true,
        );
        debugPrint('DJ play ok: audioUrl=$source playerState=${_player.state}');
        return true;
      } catch (e) {
        debugPrint('DJ play error ($candidate): $e');
        _currentUrl = null;
      }
    }

    debugPrint('DJ: oynatılamadı — musicUrl=$musicUrl');
    return false;
  }

  Future<String?> _resolveSource(String musicUrl) async {
    if (!_resolver.needsResolve(musicUrl)) return musicUrl;
    return _resolver.resolvePlayableUrl(musicUrl);
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
    if (_currentUrl == null) return;
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
    _currentUrl = null;
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
