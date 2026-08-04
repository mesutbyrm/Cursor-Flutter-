import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/room_song_remote_datasource.dart';
import '../../data/dto/room_song_dto.dart';
import 'room_song_event.dart';
import 'room_song_state.dart';

/// Oda müziği — SSE + current-song senkronu (sunucu otorite).
class RoomSongBloc extends Bloc<RoomSongEvent, RoomSongState> {
  RoomSongBloc(this._remote) : super(const RoomSongState()) {
    on<RoomSongJoinSync>(_onJoinSync);
    on<RoomSongStarted>(_onStarted);
    on<RoomSongPaused>(_onPaused);
    on<RoomSongResumed>(_onResumed);
    on<RoomSongFinished>(_onFinished);
    on<RoomSongQueueUpdated>(_onQueueUpdated);
    on<RoomSongRemoved>(_onRemoved);
    on<RoomSongSeekTick>(_onSeekTick);
    on<RoomSongMiniExpanded>((e, emit) => emit(state.copyWith(miniExpanded: e.expanded)));
    on<RoomSongFullscreen>((e, emit) => emit(state.copyWith(fullscreen: e.fullscreen)));
    on<RoomSongUserPause>(_onUserPause);
    on<RoomSongUserResume>(_onUserResume);
    on<RoomSongUserSkip>(_onUserSkip);
  }

  final RoomSongRemoteDataSource _remote;

  static const driftThresholdMs = 500;

  Future<void> _onJoinSync(
    RoomSongJoinSync event,
    Emitter<RoomSongState> emit,
  ) async {
    emit(state.copyWith(loading: true, roomId: event.roomId));
    try {
      final current = await _remote.fetchCurrentSong(event.roomId);
      final q = await _remote.fetchQueue(event.roomId);
      emit(state.copyWith(
        loading: false,
        current: current ?? q.current,
        queue: q.queue,
        serverTimeMs: current?.serverTimeMs,
      ));
    } catch (_) {
      emit(state.copyWith(loading: false, roomId: event.roomId));
    }
  }

  void _onStarted(RoomSongStarted event, Emitter<RoomSongState> emit) {
    emit(state.copyWith(
      current: event.song,
      serverTimeMs: event.song.serverTimeMs,
      localDriftMs: 0,
    ));
  }

  void _onPaused(RoomSongPaused event, Emitter<RoomSongState> emit) {
    emit(state.copyWith(current: event.song, serverTimeMs: event.song.serverTimeMs));
  }

  void _onResumed(RoomSongResumed event, Emitter<RoomSongState> emit) {
    emit(state.copyWith(current: event.song, serverTimeMs: event.song.serverTimeMs));
  }

  void _onFinished(RoomSongFinished event, Emitter<RoomSongState> emit) {
    emit(state.copyWith(clearCurrent: true));
  }

  void _onQueueUpdated(RoomSongQueueUpdated event, Emitter<RoomSongState> emit) {
    emit(state.copyWith(
      queue: event.queue,
      current: event.current ?? state.current,
    ));
  }

  void _onRemoved(RoomSongRemoved event, Emitter<RoomSongState> emit) {
    emit(state.copyWith(
      queue: event.queue,
      current: event.current ?? state.current,
    ));
  }

  void _onSeekTick(RoomSongSeekTick event, Emitter<RoomSongState> emit) {
    final c = state.current;
    if (c == null || !c.hasTrack || c.paused) return;
    final serverMs = state.serverTimeMs;
    if (serverMs == null) return;
    final expectedElapsed = c.resolvedElapsedSeconds() * 1000;
    final drift = (event.nowMs - serverMs - expectedElapsed).round().abs();
    if (drift > driftThresholdMs) {
      emit(state.copyWith(localDriftMs: drift));
    }
  }

  Future<void> _onUserPause(RoomSongUserPause event, Emitter<RoomSongState> emit) async {
    final roomId = state.roomId;
    if (roomId == null || !state.canControl) return;
    await _remote.pause(roomId);
  }

  Future<void> _onUserResume(RoomSongUserResume event, Emitter<RoomSongState> emit) async {
    final roomId = state.roomId;
    if (roomId == null || !state.canControl) return;
    await _remote.resume(roomId);
  }

  Future<void> _onUserSkip(RoomSongUserSkip event, Emitter<RoomSongState> emit) async {
    final roomId = state.roomId;
    if (roomId == null || !state.canControl) return;
    await _remote.skip(roomId);
  }

  /// SSE payload → bloc event.
  static RoomSongEvent? eventFromSse(Map<String, dynamic> payload) {
    final type = payload['type']?.toString() ?? '';
    RoomSongDto? parseCurrent() {
      final raw = payload['currentSong'];
      if (raw is Map) {
        return RoomSongDto.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    }

    List<RoomSongQueueItemDto> parseQueue() {
      final raw = payload['queue'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => RoomSongQueueItemDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final elapsed = payload['elapsed'];
    double? elapsedSec;
    if (elapsed is num) elapsedSec = elapsed.toDouble();

    switch (type) {
      case 'song_started':
        final song = parseCurrent();
        if (song == null) return null;
        return RoomSongStarted(song, elapsedSeconds: elapsedSec);
      case 'song_paused':
        final song = parseCurrent();
        if (song == null) return null;
        return RoomSongPaused(song);
      case 'song_resumed':
        final song = parseCurrent();
        if (song == null) return null;
        return RoomSongResumed(song);
      case 'song_finished':
        return const RoomSongFinished();
      case 'queue_updated':
        return RoomSongQueueUpdated(parseQueue(), current: parseCurrent());
      case 'song_removed':
        return RoomSongRemoved(
          payload['queueId']?.toString() ?? '',
          queue: parseQueue(),
          current: parseCurrent(),
        );
      default:
        return null;
    }
  }
}
