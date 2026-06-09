import 'dart:async';

import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../data/youtube_stream_resolver.dart';
import '../../domain/entities/music_queue_item.dart';
import '../audio/voice_room_dj_stream_loader.dart';
import '../audio/voice_room_music_audio_session.dart';

/// Oda arka plan müziği — DJ API `musicUrl` ile senkron (web iframe yerine stream).
class VoiceRoomDjPlayer {
  VoiceRoomDjPlayer(this._resolver, this._streamLoader);

  final YoutubeStreamResolver _resolver;
  final VoiceRoomDjStreamLoader _streamLoader;
  Future<VoiceRoomAudioHandler>? _handlerFuture;
  VoiceRoomAudioHandler? _handler;
  final ValueNotifier<VoiceRoomDjPlayback> playback =
      ValueNotifier(const VoiceRoomDjPlayback());
  String? _currentKey;
  void Function()? _onTrackComplete;
  StreamSubscription<VoiceRoomDjPlayback>? _playbackSub;

  void Function()? get onTrackComplete => _onTrackComplete;

  set onTrackComplete(void Function()? value) {
    _onTrackComplete = value;
    _handler?.onTrackComplete = value;
  }

  Future<VoiceRoomAudioHandler> _ensureHandler() {
    final existing = _handlerFuture;
    if (existing != null) return existing;
    return _handlerFuture = _initHandler();
  }

  Future<VoiceRoomAudioHandler> _initHandler() async {
    await VoiceRoomMusicAudioSession.ensureConfigured();
    final handler = await audio.AudioService.init(
      builder: () => VoiceRoomAudioHandler(onTrackComplete: _onTrackComplete),
      config: const audio.AudioServiceConfig(
        androidNotificationChannelId: 'com.mesutbyrm.canlifal.voice_music',
        androidNotificationChannelName: 'Canlifal sesli oda müziği',
        androidStopForegroundOnPause: false,
        preloadArtwork: true,
      ),
    ) as VoiceRoomAudioHandler;
    _handler = handler;
    _playbackSub = handler.playbackValueStream.listen((value) {
      playback.value = value;
    });
    return handler;
  }

  Future<bool> sync({
    String? musicUrl,
    String? fallbackYoutubeUrl,
    MusicQueueItem? nowPlaying,
    required bool playing,
    bool muted = false,
  }) async {
    final handler = await _ensureHandler();
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

        if (_currentKey == playable && handler.isPlaying) {
          return true;
        }

        try {
          await VoiceRoomMusicAudioSession.activateForPlayback();
          _currentKey = playable;
          await handler.playSource(
            playable,
            metadata: VoiceRoomAudioMetadata.fromQueueItem(
              nowPlaying,
              fallbackUrl: candidate,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 320));
          if (handler.isPlaying) {
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

  Future<void> pause() async {
    try {
      final handler = await _ensureHandler();
      await handler.pause();
    } catch (e) {
      debugPrint('DJ pause: $e');
    }
  }

  Future<void> resume() async {
    if (_currentKey == null) return;
    try {
      await VoiceRoomMusicAudioSession.activateForPlayback();
      final handler = await _ensureHandler();
      await handler.play();
    } catch (e) {
      debugPrint('DJ resume: $e');
    }
  }

  Future<void> stop() async {
    _currentKey = null;
    try {
      final handler = await _ensureHandler();
      await handler.stop();
      playback.value = const VoiceRoomDjPlayback();
    } catch (_) {}
  }

  void dispose() {
    onTrackComplete = null;
    unawaited(_handler?.disposeHandler() ?? Future<void>.value());
    unawaited(_playbackSub?.cancel());
    playback.dispose();
  }
}

class VoiceRoomAudioHandler extends audio.BaseAudioHandler with audio.SeekHandler {
  VoiceRoomAudioHandler({this.onTrackComplete}) {
    _init();
  }

  final ja.AudioPlayer _player = ja.AudioPlayer();
  final ValueNotifier<VoiceRoomDjPlayback> _playbackValue =
      ValueNotifier(const VoiceRoomDjPlayback());
  final StreamController<VoiceRoomDjPlayback> _playbackController =
      StreamController<VoiceRoomDjPlayback>.broadcast();

  Stream<VoiceRoomDjPlayback> get playbackValueStream =>
      _playbackController.stream;

  bool get isPlaying => _player.playing;

  void Function()? onTrackComplete;
  bool _completionFired = false;
  String? _currentSource;
  audio.MediaItem? _currentMediaItem;

  void _init() {
    _player.durationStream.listen((duration) {
      final d = duration ?? Duration.zero;
      _emitPlayback(_playbackValue.value.copyWith(duration: d));
      final current = _currentMediaItem;
      if (current != null && d > Duration.zero) {
        _currentMediaItem = current.copyWith(duration: d);
        mediaItem.add(_currentMediaItem);
      }
    });
    _player.positionStream.listen((position) {
      _emitPlayback(_playbackValue.value.copyWith(position: position));
    });
    _player.playingStream.listen((playing) {
      _emitPlayback(_playbackValue.value.copyWith(playing: playing));
      _broadcastPlaybackState();
    });
    _player.processingStateStream.listen((state) {
      if (state == ja.ProcessingState.completed && !_completionFired) {
        _completionFired = true;
        _emitPlayback(_playbackValue.value.copyWith(playing: false));
        _broadcastPlaybackState(processingState: audio.AudioProcessingState.completed);
        onTrackComplete?.call();
      } else {
        _broadcastPlaybackState(processingState: _mapProcessingState(state));
      }
    });
  }

  Future<void> playSource(
    String source, {
    required VoiceRoomAudioMetadata metadata,
  }) async {
    _completionFired = false;
    if (_currentSource != source) {
      _currentSource = source;
      final item = metadata.toMediaItem(source);
      _currentMediaItem = item;
      mediaItem.add(item);
      queue.add([item]);
      final audioSource = source.startsWith('/')
          ? ja.AudioSource.file(source, tag: item)
          : ja.AudioSource.uri(Uri.parse(source), tag: item);
      await _player.stop();
      await _player.setAudioSource(audioSource);
      _emitPlayback(const VoiceRoomDjPlayback());
    }
    await _player.setVolume(1.0);
    await play();
  }

  @override
  Future<void> play() async {
    await _player.play();
    _broadcastPlaybackState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastPlaybackState();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _emitPlayback(_playbackValue.value.copyWith(position: position));
    _broadcastPlaybackState();
  }

  @override
  Future<void> stop() async {
    _currentSource = null;
    _completionFired = false;
    _currentMediaItem = null;
    await _player.stop();
    _emitPlayback(const VoiceRoomDjPlayback());
    mediaItem.add(null);
    queue.add(const []);
    playbackState.add(
      playbackState.value.copyWith(
        processingState: audio.AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
      ),
    );
  }

  Future<void> disposeHandler() async {
    await stop();
    await _player.dispose();
    _playbackValue.dispose();
    await _playbackController.close();
  }

  void _emitPlayback(VoiceRoomDjPlayback value) {
    _playbackValue.value = value;
    if (!_playbackController.isClosed) {
      _playbackController.add(value);
    }
  }

  void _broadcastPlaybackState({audio.AudioProcessingState? processingState}) {
    final controls = _player.playing
        ? [audio.MediaControl.pause, audio.MediaControl.stop]
        : [audio.MediaControl.play, audio.MediaControl.stop];
    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {
          audio.MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1],
        processingState:
            processingState ?? _mapProcessingState(_player.processingState),
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  audio.AudioProcessingState _mapProcessingState(ja.ProcessingState state) {
    switch (state) {
      case ja.ProcessingState.idle:
        return audio.AudioProcessingState.idle;
      case ja.ProcessingState.loading:
        return audio.AudioProcessingState.loading;
      case ja.ProcessingState.buffering:
        return audio.AudioProcessingState.buffering;
      case ja.ProcessingState.ready:
        return audio.AudioProcessingState.ready;
      case ja.ProcessingState.completed:
        return audio.AudioProcessingState.completed;
    }
  }
}

class VoiceRoomAudioMetadata {
  const VoiceRoomAudioMetadata({
    required this.id,
    required this.title,
    this.artist,
    this.artUri,
    this.duration,
  });

  factory VoiceRoomAudioMetadata.fromQueueItem(
    MusicQueueItem? item, {
    required String fallbackUrl,
  }) {
    return VoiceRoomAudioMetadata(
      id: item?.id ?? fallbackUrl,
      title: item?.title.trim().isNotEmpty == true
          ? item!.title.trim()
          : 'Canlifal oda müziği',
      artist: item?.artistLine.trim().isNotEmpty == true
          ? item!.artistLine.trim()
          : 'Canlifal',
      artUri: item?.thumbUrl != null && item!.thumbUrl!.trim().isNotEmpty
          ? Uri.tryParse(item.thumbUrl!.trim())
          : null,
      duration: _parseDuration(item?.duration),
    );
  }

  final String id;
  final String title;
  final String? artist;
  final Uri? artUri;
  final Duration? duration;

  audio.MediaItem toMediaItem(String source) {
    return audio.MediaItem(
      id: source,
      title: title,
      artist: artist,
      album: 'Canlifal Sesli Oda',
      duration: duration,
      artUri: artUri,
      extras: {'queueId': id},
    );
  }

  static Duration? _parseDuration(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty || !value.contains(':')) return null;
    final parts = value.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    }
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    }
    return null;
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

  VoiceRoomDjPlayback copyWith({
    Duration? position,
    Duration? duration,
    bool? playing,
  }) {
    return VoiceRoomDjPlayback(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playing: playing ?? this.playing,
    );
  }

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  Duration get remaining {
    if (duration <= position) return Duration.zero;
    return duration - position;
  }
}
