import 'dart:async';

import '../../../features/visual_fx/data/fx_dedupe_store.dart';
import '../data/site_animation_cache.dart';
import '../domain/site_animation_asset.dart';
import '../domain/site_animation_command.dart';
import 'site_animation_state.dart';

typedef SiteAnimationStateListener = void Function(SiteAnimationState state);

/// Merkezi site animation motoru — kuyruk, dedupe, preload, dispose.
class SiteAnimationManager {
  SiteAnimationManager({
    FxDedupeStore? dedupe,
    SiteAnimationStateListener? onStateChanged,
  })  : _dedupe = dedupe ?? FxDedupeStore(),
        _onStateChanged = onStateChanged;

  final FxDedupeStore _dedupe;
  final SiteAnimationStateListener? _onStateChanged;
  final _queue = <SiteAnimationCommand>[];
  final _cancelled = <String>{};
  final _preloaded = <String>{};

  SiteAnimationState _state = const SiteAnimationState();
  Timer? _activeTimer;
  var _disposed = false;

  SiteAnimationState get state => _state;

  void _emit(SiteAnimationState next) {
    _state = next;
    _onStateChanged?.call(next);
  }

  /// Anında oynat — aktif yoksa başlat, varsa kuyruğa al.
  void play(SiteAnimationCommand command) {
    if (_disposed) return;
    if (!_dedupe.markIfNew(command.eventId)) return;
    if (_cancelled.remove(command.eventId)) {}

    if (_state.active == null) {
      _start(command);
      return;
    }
    _enqueue(command);
  }

  /// Öncelik sırasına göre kuyruğa ekle.
  void queue(SiteAnimationCommand command) {
    if (_disposed) return;
    if (!_dedupe.markIfNew(command.eventId)) return;
    if (_cancelled.contains(command.eventId)) return;
    _enqueue(command);
  }

  void _enqueue(SiteAnimationCommand command) {
    if (_queue.any((c) => c.eventId == command.eventId)) return;
    if (_state.active?.eventId == command.eventId) return;

    _queue.add(command);
    _queue.sort((a, b) => b.priority.compareTo(a.priority));
    _emit(_state.copyWith(queueLength: _queue.length));
    unawaited(preload(command.asset));
  }

  void cancel(String eventId) {
    final id = eventId.trim();
    if (id.isEmpty) return;
    _cancelled.add(id);
    _queue.removeWhere((c) => c.eventId == id);
    if (_state.active?.eventId == id) {
      _finishActive();
    } else {
      _emit(_state.copyWith(queueLength: _queue.length));
    }
  }

  void clearQueue() {
    _queue.clear();
    _emit(_state.copyWith(queueLength: 0));
  }

  Future<void> preload(SiteAnimationAsset asset) async {
    if (_disposed) return;
    final key = asset.cacheKey;
    if (key.isEmpty || _preloaded.contains(key)) return;
    _preloaded.add(key);
    _emit(_state.copyWith(preloading: true));
    try {
      await SiteAnimationCache.preload(asset);
    } catch (_) {
      // Network hatası — fallback UI devreye girer.
    } finally {
      _emit(_state.copyWith(preloading: false));
    }
  }

  void handleRoomEvent(
    String event,
    Map<String, dynamic> payload, {
    required String roomId,
    String? ownerId,
    required SiteAnimationCommand? Function() parse,
  }) {
    if (_disposed) return;
    final command = parse();
    if (command == null || command.roomId != roomId) return;

    if (command.type.isSeatAnchored &&
        command.type.name.contains('seat') &&
        command.layout.fromSeatIndex != null) {
      _emit(_state.copyWith(seatTransition: command));
    }

    play(command);
  }

  void onActiveFinished(String eventId) {
    if (_state.active?.eventId != eventId) return;
    _finishActive();
  }

  void _start(SiteAnimationCommand command) {
    _activeTimer?.cancel();
    unawaited(preload(command.asset));
    _emit(
      _state.copyWith(
        active: command,
        queueLength: _queue.length,
      ),
    );
    _activeTimer = Timer(command.displayDuration, () {
      _finishActive();
    });
  }

  void _finishActive() {
    _activeTimer?.cancel();
    _activeTimer = null;
    if (_queue.isEmpty) {
      _emit(_state.copyWith(clearActive: true, clearSeatTransition: true));
      return;
    }
    final next = _queue.removeAt(0);
    _emit(
      _state.copyWith(
        clearActive: true,
        clearSeatTransition: true,
        queueLength: _queue.length,
      ),
    );
    _start(next);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _activeTimer?.cancel();
    _activeTimer = null;
    _queue.clear();
    _cancelled.clear();
    _preloaded.clear();
    _dedupe.clear();
    _emit(const SiteAnimationState());
  }
}
