import 'dart:async';

import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../data/services/voice_room_music_pipeline_log.dart';
import '../../data/youtube_stream_resolver.dart';
import '../../domain/entities/music_queue_item.dart';
import '../audio/voice_room_dj_stream_loader.dart';
import '../audio/voice_room_music_audio_session.dart';
import 'voice_room_music_control_delegate.dart';

/// Oda arka plan müziği — DJ API `musicUrl` ile senkron (web iframe yerine stream).
///
/// Yığın: [just_audio] + [audio_service] (just_audio_background ile aynı bildirim modeli).
class VoiceRoomDjPlayer {
  VoiceRoomDjPlayer(this._resolver, this._streamLoader);

  final YoutubeStreamResolver _resolver;
  final VoiceRoomDjStreamLoader _streamLoader;
  Future<VoiceRoomAudioHandler>? _handlerFuture;
  VoiceRoomAudioHandler? _handler;
  final ValueNotifier<VoiceRoomDjPlayback> playback =
      ValueNotifier(const VoiceRoomDjPlayback());
  final ValueNotifier<VoiceRoomMusicDiagnostics> diagnostics =
      ValueNotifier(const VoiceRoomMusicDiagnostics());
  String? _currentKey;
  bool _muted = false;
  void Function()? _onTrackComplete;
  StreamSubscription<VoiceRoomDjPlayback>? _playbackSub;
  VoiceRoomMusicControlDelegate? controlDelegate;

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
      builder: () => VoiceRoomAudioHandler(
        onTrackComplete: _onTrackComplete,
        delegateProvider: () => controlDelegate,
      ),
      config: const audio.AudioServiceConfig(
        androidNotificationChannelId: 'com.mesutbyrm.canlifal.voice_music',
        androidNotificationChannelName: 'Canlifal sesli oda müziği',
        androidNotificationChannelDescription:
            'Sesli sohbet odası DJ müziği ve medya kontrolleri',
        androidStopForegroundOnPause: false,
        preloadArtwork: true,
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    ) as VoiceRoomAudioHandler;
    _handler = handler;
    handler.onDiagnosticsChanged = (value) {
      diagnostics.value = value;
    };
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
    _muted = muted;
    final handler = await _ensureHandler();

    if (!playing || musicUrl == null || musicUrl.isEmpty) {
      if (!playing) await stop();
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

        if (_currentKey == playable && handler.isPlaying && !_muted) {
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
            inputMusicUrl: musicUrl,
            candidateLabel: candidate,
          );
          await handler.setVolume(_muted ? 0.0 : 1.0);
          final started = await handler.waitUntilPlaying(
            timeout: const Duration(seconds: 4),
          );
          diagnostics.value = handler.diagnostics.copyWith(
            serverMusicUrl: musicUrl,
            playbackSource: candidate,
            resolvedStreamUrl: playable,
            muted: _muted,
            lastPhase: started ? 'sync_ok' : 'sync_verify_failed',
          );
          if (started) {
            debugPrint('DJ play ok: $playable');
            return true;
          }
          VoiceRoomMusicPipelineLog.justAudioError(
            StateError(
              'play_not_started processing=${handler.diagnostics.processingState} '
              'playing=${handler.isPlaying} muted=$_muted',
            ),
            StackTrace.current,
            phase: 'sync_verify',
            url: playable,
          );
        } on ja.PlayerException catch (e, st) {
          VoiceRoomMusicPipelineLog.justAudioError(
            e,
            st,
            phase: 'sync_PlayerException',
            url: candidate,
          );
          debugPrint('DJ play error ($candidate): $e');
          _currentKey = null;
        } catch (e, st) {
          VoiceRoomMusicPipelineLog.justAudioError(
            e,
            st,
            phase: 'sync',
            url: candidate,
          );
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

  Future<void> setMuted(bool muted) async {
    _muted = muted;
    try {
      final handler = await _ensureHandler();
      await handler.setVolume(muted ? 0.0 : 1.0);
      if (muted) {
        await handler.pauseLocal();
      } else if (_currentKey != null) {
        await handler.playLocal();
      }
    } catch (e) {
      debugPrint('DJ mute: $e');
    }
  }

  Future<void> pauseLocal() async {
    try {
      final handler = await _ensureHandler();
      await handler.pauseLocal();
    } catch (e) {
      debugPrint('DJ pauseLocal: $e');
    }
  }

  Future<void> pause() async {
    try {
      final handler = await _ensureHandler();
      await handler.pauseLocal();
    } catch (e) {
      debugPrint('DJ pause: $e');
    }
  }

  Future<void> resumeLocal() async {
    if (_currentKey == null) return;
    try {
      await VoiceRoomMusicAudioSession.activateForPlayback();
      final handler = await _ensureHandler();
      await handler.setVolume(_muted ? 0.0 : 1.0);
      await handler.playLocal();
    } catch (e) {
      debugPrint('DJ resumeLocal: $e');
    }
  }

  Future<void> resume() async => resumeLocal();

  Future<void> seekToStart() async {
    try {
      final handler = await _ensureHandler();
      await handler.seek(Duration.zero);
    } catch (e) {
      debugPrint('DJ seekToStart: $e');
    }
  }

  Future<void> stop() async {
    _currentKey = null;
    _muted = false;
    try {
      final handler = await _ensureHandler();
      await handler.stop();
      playback.value = const VoiceRoomDjPlayback();
      diagnostics.value = const VoiceRoomMusicDiagnostics();
    } catch (_) {}
  }

  Future<void> shutdown() async {
    controlDelegate = null;
    onTrackComplete = null;
    await stop();
    try {
      await audio.AudioService.stop();
    } catch (_) {}
  }

  void dispose() {
    unawaited(shutdown());
    unawaited(_handler?.disposeHandler() ?? Future<void>.value());
    unawaited(_playbackSub?.cancel());
    playback.dispose();
    diagnostics.dispose();
  }
}

/// Mini player altında gösterilen oynatma teşhis bilgisi.
class VoiceRoomMusicDiagnostics {
  const VoiceRoomMusicDiagnostics({
    this.serverMusicUrl,
    this.playbackSource,
    this.resolvedStreamUrl,
    this.processingState,
    this.isPlaying,
    this.muted,
    this.lastError,
    this.lastPhase,
  });

  final String? serverMusicUrl;
  final String? playbackSource;
  final String? resolvedStreamUrl;
  final String? processingState;
  final bool? isPlaying;
  final bool? muted;
  final String? lastError;
  final String? lastPhase;

  VoiceRoomMusicDiagnostics copyWith({
    String? serverMusicUrl,
    String? playbackSource,
    String? resolvedStreamUrl,
    String? processingState,
    bool? isPlaying,
    bool? muted,
    String? lastError,
    String? lastPhase,
  }) {
    return VoiceRoomMusicDiagnostics(
      serverMusicUrl: serverMusicUrl ?? this.serverMusicUrl,
      playbackSource: playbackSource ?? this.playbackSource,
      resolvedStreamUrl: resolvedStreamUrl ?? this.resolvedStreamUrl,
      processingState: processingState ?? this.processingState,
      isPlaying: isPlaying ?? this.isPlaying,
      muted: muted ?? this.muted,
      lastError: lastError ?? this.lastError,
      lastPhase: lastPhase ?? this.lastPhase,
    );
  }
}

class VoiceRoomAudioHandler extends audio.BaseAudioHandler
    with audio.SeekHandler {
  VoiceRoomAudioHandler({
    this.onTrackComplete,
    required VoiceRoomMusicControlDelegate? Function() delegateProvider,
  }) : _delegateProvider = delegateProvider {
    _init();
  }

  final ja.AudioPlayer _player = ja.AudioPlayer();
  final ValueNotifier<VoiceRoomDjPlayback> _playbackValue =
      ValueNotifier(const VoiceRoomDjPlayback());
  final StreamController<VoiceRoomDjPlayback> _playbackController =
      StreamController<VoiceRoomDjPlayback>.broadcast();
  final VoiceRoomMusicControlDelegate? Function() _delegateProvider;

  Stream<VoiceRoomDjPlayback> get playbackValueStream =>
      _playbackController.stream;

  bool get isPlaying => _player.playing;
  bool get hasLoadedSource => _currentSource != null;
  VoiceRoomMusicDiagnostics get diagnostics => _diagnostics;

  void Function()? onTrackComplete;
  void Function(VoiceRoomMusicDiagnostics diagnostics)? onDiagnosticsChanged;
  bool _completionFired = false;
  String? _currentSource;
  audio.MediaItem? _currentMediaItem;
  VoiceRoomMusicDiagnostics _diagnostics = const VoiceRoomMusicDiagnostics();

  VoiceRoomMusicControlDelegate? get _delegate => _delegateProvider();

  void _publishDiagnostics() {
    onDiagnosticsChanged?.call(_diagnostics);
  }

  Future<bool> waitUntilPlaying({required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      _refreshDiagnostics();
      if (_player.playing &&
          (_player.processingState == ja.ProcessingState.ready ||
              _player.processingState == ja.ProcessingState.buffering)) {
        return true;
      }
      if (_player.processingState == ja.ProcessingState.completed) {
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    _refreshDiagnostics();
    return _player.playing;
  }

  void _refreshDiagnostics() {
    _diagnostics = _diagnostics.copyWith(
      processingState: _player.processingState.name,
      isPlaying: _player.playing,
    );
    _publishDiagnostics();
  }

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
      _refreshDiagnostics();
      VoiceRoomMusicPipelineLog.playState(
        playing: _player.playing,
        processingState: state.name,
        positionMs: _player.position.inMilliseconds,
        url: _currentSource,
      );
      if (state == ja.ProcessingState.completed && !_completionFired) {
        _completionFired = true;
        _emitPlayback(_playbackValue.value.copyWith(playing: false));
        _broadcastPlaybackState(
          processingState: audio.AudioProcessingState.completed,
        );
        onTrackComplete?.call();
      } else {
        _broadcastPlaybackState(processingState: _mapProcessingState(state));
      }
    });
    _player.playbackEventStream.listen(
      (event) {
        if (event.processingState == ja.ProcessingState.completed) return;
      },
      onError: (Object e, StackTrace st) {
        _diagnostics = _diagnostics.copyWith(
          lastError: e.toString(),
          lastPhase: 'playbackEventStream',
        );
        VoiceRoomMusicPipelineLog.justAudioError(
          e,
          st,
          phase: 'playbackEventStream',
          url: _currentSource,
        );
      },
    );
    _player.playerStateStream.listen((state) {
      _refreshDiagnostics();
      if (state.processingState == ja.ProcessingState.loading ||
          state.processingState == ja.ProcessingState.buffering) {
        VoiceRoomMusicPipelineLog.playState(
          playing: state.playing,
          processingState: state.processingState.name,
          positionMs: state.position.inMilliseconds,
          url: _currentSource,
        );
      }
    });
  }

  Future<void> playSource(
    String source, {
    required VoiceRoomAudioMetadata metadata,
    String? inputMusicUrl,
    String? candidateLabel,
  }) async {
    _completionFired = false;
    if (_currentSource != source) {
      _currentSource = source;
      final item = metadata.toMediaItem(source);
      _currentMediaItem = item;
      mediaItem.add(item);
      queue.add([item]);
      final sourceType = source.startsWith('/') ? 'file' : 'uri';
      VoiceRoomMusicPipelineLog.beforeSetAudioSource(
        sourceUrl: source,
        sourceType: sourceType,
        metadataTitle: metadata.title,
      );
      VoiceRoomMusicPipelineLog.compareFields(
        stage: 'pre_setAudioSource',
        roomId: 'local',
        serverMusicUrl: inputMusicUrl ?? candidateLabel,
        playbackSource: candidateLabel ?? inputMusicUrl,
        resolvedStreamUrl: source,
        videoId: VoiceRoomMusicPipelineLog.videoIdFromUrl(
          candidateLabel ?? inputMusicUrl ?? '',
        ),
      );
      final audioSource = source.startsWith('/')
          ? ja.AudioSource.file(source, tag: item)
          : ja.AudioSource.uri(Uri.parse(source), tag: item);
      await _player.stop();
      _diagnostics = _diagnostics.copyWith(
        resolvedStreamUrl: source,
        playbackSource: candidateLabel ?? inputMusicUrl,
        serverMusicUrl: inputMusicUrl,
        lastPhase: 'setAudioSource',
      );
      _publishDiagnostics();
      try {
        await _player.setAudioSource(audioSource);
      } on ja.PlayerException catch (e, st) {
        VoiceRoomMusicPipelineLog.justAudioError(
          e,
          st,
          phase: 'setAudioSource',
          url: source,
        );
        rethrow;
      }
      _emitPlayback(const VoiceRoomDjPlayback());
    }
    await playLocal();
  }

  Future<void> playLocal() async {
    VoiceRoomMusicPipelineLog.playEntered(
      sourceUrl: _currentSource ?? '(none)',
    );
    try {
      await _player.play();
      _refreshDiagnostics();
      VoiceRoomMusicPipelineLog.playState(
        playing: _player.playing,
        processingState: _player.processingState.name,
        positionMs: _player.position.inMilliseconds,
        url: _currentSource,
      );
    } on ja.PlayerException catch (e, st) {
      _diagnostics = _diagnostics.copyWith(
        lastError: e.toString(),
        lastPhase: 'play()',
      );
      VoiceRoomMusicPipelineLog.justAudioError(
        e,
        st,
        phase: 'play()',
        url: _currentSource,
      );
      rethrow;
    }
    _broadcastPlaybackState();
  }

  Future<void> pauseLocal() async {
    await _player.pause();
    _broadcastPlaybackState();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  @override
  Future<void> play() async {
    final delegate = _delegate;
    if (delegate?.syncServerControls == true && delegate?.onPlay != null) {
      await delegate!.onPlay!();
      return;
    }
    await playLocal();
  }

  @override
  Future<void> pause() async {
    final delegate = _delegate;
    if (delegate?.syncServerControls == true && delegate?.onPause != null) {
      await delegate!.onPause!();
      return;
    }
    await pauseLocal();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _emitPlayback(_playbackValue.value.copyWith(position: position));
    _broadcastPlaybackState();
  }

  @override
  Future<void> stop() async {
    final delegate = _delegate;
    if (delegate?.onStop != null) {
      await delegate!.onStop!();
      return;
    }
    await stopLocal();
  }

  Future<void> stopLocal() async {
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

  @override
  Future<void> skipToNext() async {
    final delegate = _delegate;
    if (delegate?.onSkipToNext != null) {
      await delegate!.onSkipToNext!();
      return;
    }
    await super.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    final delegate = _delegate;
    if (delegate?.onSkipToPrevious != null) {
      await delegate!.onSkipToPrevious!();
      return;
    }
    await seek(Duration.zero);
  }

  Future<void> disposeHandler() async {
    await stopLocal();
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
    final playing = _player.playing;
    final controls = <audio.MediaControl>[
      audio.MediaControl.skipToPrevious,
      playing ? audio.MediaControl.pause : audio.MediaControl.play,
      audio.MediaControl.skipToNext,
      audio.MediaControl.stop,
    ];
    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {
          audio.MediaAction.seek,
          audio.MediaAction.seekForward,
          audio.MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState:
            processingState ?? _mapProcessingState(_player.processingState),
        playing: playing,
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
