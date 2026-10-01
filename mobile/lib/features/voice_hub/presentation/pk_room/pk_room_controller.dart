import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../data/pk_room_api.dart';
import '../../domain/pk_room/pk_gift_queue_core.dart';
import '../../domain/pk_room/pk_room_match.dart';
import '../../domain/pk_room/pk_server_clock.dart';
import '../../domain/pk_room/pk_wire_event.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_gift_providers.dart';
import '../providers/voice_room_session_registry.dart';

/// Tek sunucu-saati kaynağı (uygulama genelinde bir tane).
final pkServerClockProvider = Provider<PkServerClock>((ref) => PkServerClock());

final pkRoomApiProvider = Provider<PkRoomApi>(
  (ref) => PkRoomApi(ref.watch(dioProvider)),
);

/// Süresi dolduktan sonra sunucudan sonuç beklerken azami deneme.
const _kFinalizeAttempts = 5;
const _kFinalizeGap = Duration(seconds: 2);

/// Hediye kartı görünme süresi (fade-out öncesi) ve kartlar arası boşluk.
const pkGiftToastVisible = Duration(seconds: 5);
const pkGiftToastGap = Duration(milliseconds: 350);

/// Oda içi PK sonucu (başkası bitirdiğinde / süre dolunca kısa bildirim).
class PkRoomResult {
  const PkRoomResult({
    required this.battleId,
    required this.score1,
    required this.score2,
    required this.winnerSide,
    required this.isDraw,
    required this.mySide,
  });

  final String battleId;
  final int score1;
  final int score2;
  final int? winnerSide;
  final bool isDraw;

  /// Ben hangi takımdaydım (0 = izleyici).
  final int mySide;
}

class PkRoomState {
  const PkRoomState({
    this.match,
    this.ending = false,
    this.muteOpposing = false,
    this.error,
    this.result,
  });

  /// Odadaki güncel PK (biten maç da burada kalabilir; [overlayVisible] karar verir).
  final PkRoomMatch? match;

  /// "PK Bitir" isteği uçuşta (arayüz zaten normale döndü).
  final bool ending;

  /// Karşı takımın sesi BU CİHAZDA kapalı (yerel; sunucuya gitmez).
  final bool muteOpposing;
  final String? error;
  final PkRoomResult? result;

  bool get overlayVisible => match?.phase.showsOverlay ?? false;

  PkRoomState copyWith({
    PkRoomMatch? match,
    bool clearMatch = false,
    bool? ending,
    bool? muteOpposing,
    String? error,
    bool clearError = false,
    PkRoomResult? result,
    bool clearResult = false,
  }) {
    return PkRoomState(
      match: clearMatch ? null : (match ?? this.match),
      ending: ending ?? this.ending,
      muteOpposing: muteOpposing ?? this.muteOpposing,
      error: clearError ? null : (error ?? this.error),
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

/// PK hediye kartları: ekranda tek kart, en fazla son 3 (bkz. [PkGiftQueueCore]).
class PkGiftToastController {
  PkGiftToastController({
    this.visible = pkGiftToastVisible,
    this.gap = pkGiftToastGap,
  });

  final Duration visible;
  final Duration gap;
  final PkGiftQueueCore _core = PkGiftQueueCore();

  /// Şu an görünen kart (null → gizli / fade-out).
  final ValueNotifier<PkGiftToast?> current = ValueNotifier<PkGiftToast?>(null);

  Timer? _timer;
  var _disposed = false;

  void add(PkGiftToast toast) {
    if (_disposed) return;
    final wasEmpty = _core.current == null;
    if (!_core.add(toast)) return;
    if (wasEmpty && _timer == null) _show(_core.current);
  }

  void _show(PkGiftToast? toast) {
    if (_disposed) return;
    current.value = toast;
    _timer?.cancel();
    if (toast == null) {
      _timer = null;
      return;
    }
    _timer = Timer(visible, _hide);
  }

  void _hide() {
    if (_disposed) return;
    current.value = null; // fade-out
    _timer = Timer(gap, () {
      if (_disposed) return;
      final next = _core.advance();
      _timer = null;
      if (next != null) _show(next);
    });
  }

  void clear() {
    _timer?.cancel();
    _timer = null;
    _core.clear();
    if (!_disposed) current.value = null;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    current.dispose();
  }
}

/// Oda içi PK'nın **tek** durum/zamanlayıcı merkezi.
///
///  * Sayaç tek `Timer.periodic`'tir ve `endsAt - sunucuSaati` ile hesaplanır;
///    arayüz yalnızca [remainingSeconds]'u dinler (widget rebuild sayacı etkilemez).
///  * Her olay yalnızca ilgili alanı günceller: hediye puanı (`PK_SCORE`)
///    süreyi/fazı değiştirmez, davet popup'ı açmaz.
///  * "PK Bitir" iyimser çalışır: arayüz hemen normal odaya döner.
class PkRoomController extends FamilyNotifier<PkRoomState, String> {
  late final PkServerClock _clock;
  late final PkRoomApi _api;
  Timer? _ticker;
  Timer? _finalizeTimer;
  StreamSubscription<LiveGiftEvent>? _giftSub;
  final Map<String, DateTime> _closed = {};
  final Set<String> _timeUpHandled = {};
  var _loading = false;
  String? _alternateKey;

  /// Kalan süre (saniye, yukarı yuvarlanmış). Yalnızca değer değişince bildirir.
  final ValueNotifier<int> remainingSeconds = ValueNotifier<int>(0);
  final PkGiftToastController gifts = PkGiftToastController();

  @override
  PkRoomState build(String arg) {
    _clock = ref.watch(pkServerClockProvider);
    _api = ref.watch(pkRoomApiProvider);
    ref.onDispose(() {
      _ticker?.cancel();
      _finalizeTimer?.cancel();
      _giftSub?.cancel();
      remainingSeconds.dispose();
      gifts.dispose();
    });
    // SSE yeniden bağlandı → sunucudan güncel PK'yı al (yerel sayaç yeniden
    // başlatılmaz; yalnızca otoriter endsAt güncellenir).
    ref.listen<bool>(voiceRoomActiveSseConnectedProvider, (prev, next) {
      if (next && prev == false) unawaited(loadCurrent());
    });
    return const PkRoomState();
  }

  /// Oda slug'ı gibi alternatif anahtar (REST için).
  void attachAlternateKey(String? alt) {
    final t = alt?.trim() ?? '';
    _alternateKey = t.isEmpty || t == arg ? null : t;
  }

  PkRoomMatch? get match => state.match;

  // ───────────────────────── Girdi: REST ─────────────────────────

  /// `GET /api/chat/rooms/{id}/pk` — odaya girişte, SSE yeniden bağlanınca,
  /// süre dolunca. Sunucu durumu otoritedir.
  Future<void> loadCurrent() async {
    if (_loading) return;
    _loading = true;
    try {
      final json = await _api.fetchCurrent(arg, alternateRoomId: _alternateKey);
      _clock.observeIso(json?['serverNow']?.toString());
      if (json == null) {
        _onNoBattle();
        return;
      }
      _applyJson(json);
    } on ApiException catch (e) {
      if (kDebugMode) debugPrint('[pk-room] load error: ${e.message}');
    } catch (_) {
      // Ağ hatası: mevcut (otoriter endsAt'lı) durum korunur.
    } finally {
      _loading = false;
    }
  }

  void _onNoBattle() {
    final m = state.match;
    if (m != null && m.isLive) {
      _finish(m.copyWith(phase: PkRoomPhase.finished, status: 'completed'));
    }
  }

  // ───────────────────────── Girdi: SSE ─────────────────────────

  /// SSE `pk` olayı (oda içi). Davet olayları ve başka odaya ait olaylar yok sayılır.
  void ingest(PkWireEvent e) {
    if (!e.inRoom || e.battleId.isEmpty) return;
    if (e.kind == PkWireKind.invite || e.kind == PkWireKind.unknown) return;
    _clock.observeIso(e.raw['serverNow']?.toString());

    if (e.kind == PkWireKind.score) {
      _applyScore(e);
      return;
    }
    _applyJson(e.raw, kind: e.kind);
  }

  void _applyScore(PkWireEvent e) {
    final cur = state.match;
    if (cur == null || cur.battleId != e.battleId) {
      // Bilmediğimiz maçın skoru: tam durumu sunucudan çek.
      unawaited(loadCurrent());
      return;
    }
    if (!cur.phase.showsOverlay || _isClosed(cur.battleId)) return;
    final r = e.raw;
    int? i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v');
    final s1 = i(r['score1']);
    final s2 = i(r['score2']);
    if (s1 == null || s2 == null) return;
    state = state.copyWith(
      match: cur.withScorePatch(
        score1: s1,
        score2: s2,
        receiverId: r['receiverId']?.toString(),
        addedAmount: i(r['addedAmount']) ?? 0,
      ),
    );
  }

  void _applyJson(Map<String, dynamic> json, {PkWireKind? kind}) {
    final next = PkRoomMatch.fromJson(
      json,
      previous: state.match,
      roomIdFallback: arg,
      serverNow: _clock.now(),
    );
    if (next == null) return;
    // Kapattığımız (iyimser bitirilen) maçı canlı bir olay diriltmesin.
    if (_isClosed(next.battleId) && !next.phase.isTerminal) return;
    // Başka bir maçın eski/gecikmiş olayı mevcut canlı maçı ezmesin.
    final cur = state.match;
    if (cur != null &&
        cur.battleId != next.battleId &&
        cur.isLive &&
        !next.phase.showsOverlay) {
      return;
    }

    if (next.phase.isTerminal) {
      _finish(next, natural: true);
      return;
    }
    if (next.phase == PkRoomPhase.idle || next.phase == PkRoomPhase.invited) {
      return; // davet/boş: oda içi PK ekranı yok
    }
    state = state.copyWith(match: next, clearError: true);
    _syncTicker();
    _attachGifts();
  }

  // ───────────────────────── Zamanlayıcı ─────────────────────────

  void _syncTicker() {
    final m = state.match;
    if (m == null || !m.isLive) {
      _stopTicker();
      return;
    }
    _tick();
    _ticker ??= Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _tick(),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (remainingSeconds.value != 0) remainingSeconds.value = 0;
  }

  void _tick() {
    final m = state.match;
    if (m == null || !m.isLive) {
      _stopTicker();
      return;
    }
    final now = _clock.now();
    int ms;
    if (m.phase == PkRoomPhase.starting) {
      final until = m.startingUntil;
      ms = until == null
          ? m.durationSec * 1000
          : until.difference(now).inMilliseconds;
      if (ms < 0) ms = 0;
      if (ms == 0 && until != null) _nudgeStart(m);
    } else {
      ms = m.remainingMsAt(now);
    }
    final secs = (ms / 1000).ceil();
    if (remainingSeconds.value != secs) remainingSeconds.value = secs;

    if (m.phase == PkRoomPhase.active && ms <= 0) _onTimeUp(m);
  }

  DateTime? _lastStartNudge;
  void _nudgeStart(PkRoomMatch m) {
    final at = DateTime.now();
    final last = _lastStartNudge;
    if (last != null && at.difference(last) < const Duration(seconds: 2))
      return;
    _lastStartNudge = at;
    unawaited(loadCurrent()); // PK_STARTED kaçtıysa sunucudan al
  }

  // ───────────────────────── Süre doldu ─────────────────────────

  void _onTimeUp(PkRoomMatch m) {
    if (!_timeUpHandled.add(m.battleId)) return;
    state = state.copyWith(match: m.copyWith(phase: PkRoomPhase.finishing));
    unawaited(_finalize(m.battleId, 0));
  }

  /// Sunucu `PK_ENDED`'i göndermese bile ekranın takılı kalmasını önler:
  /// GET (sunucu süresi dolan PK'yı kapatır) birkaç kez denenir, sonra yerelde bitirilir.
  Future<void> _finalize(String battleId, int attempt) async {
    await loadCurrent();
    final m = state.match;
    if (m == null ||
        m.battleId != battleId ||
        m.phase != PkRoomPhase.finishing) {
      return; // sunucu bitirdi (ya da maç değişti)
    }
    if (attempt + 1 >= _kFinalizeAttempts) {
      _finish(
        m.copyWith(phase: PkRoomPhase.finished, status: 'completed'),
        natural: true,
      );
      return;
    }
    _finalizeTimer?.cancel();
    _finalizeTimer = Timer(
      _kFinalizeGap,
      () => unawaited(_finalize(battleId, attempt + 1)),
    );
  }

  // ───────────────────────── Bitiş ─────────────────────────

  bool _isClosed(String id) {
    final at = _closed[id];
    if (at == null) return false;
    if (DateTime.now().difference(at) > const Duration(minutes: 10)) {
      _closed.remove(id);
      return false;
    }
    return true;
  }

  void _finish(PkRoomMatch ended, {bool natural = false}) {
    _closed[ended.battleId] = DateTime.now();
    final myId = ref.read(authControllerProvider).valueOrNull?.id;
    final wasLive = state.match?.isLive ?? false;
    _stopTicker();
    _finalizeTimer?.cancel();
    _detachGifts();
    gifts.clear();
    state = state.copyWith(
      match: ended.copyWith(phase: PkRoomPhase.finished),
      muteOpposing: false, // PK bitince yerel susturma kalkar
      result: (natural && wasLive)
          ? PkRoomResult(
              battleId: ended.battleId,
              score1: ended.score1,
              score2: ended.score2,
              winnerSide: ended.winnerSide,
              isDraw: ended.isDraw,
              mySide: ended.sideOf(myId),
            )
          : null,
    );
    // Eski global PK deposu (yalnızca durum ayna) — davet/strip tarafı temizlensin.
    try {
      ref.read(pkBattleRemoteProvider.notifier).clear();
    } catch (_) {}
  }

  /// "PK Bitir": **iyimser** — arayüz hemen normal odaya döner, istek arkadan gider.
  /// Başarısız olursa (ör. yetki yok) PK geri gelir ve hata gösterilir.
  Future<void> endNow() async {
    final m = state.match;
    if (m == null || !m.isLive || state.ending) return;
    final snapshot = m;
    _closed[m.battleId] = DateTime.now();
    _stopTicker();
    _finalizeTimer?.cancel();
    gifts.clear();
    state = state.copyWith(
      match: m.copyWith(phase: PkRoomPhase.finished, status: 'completed'),
      ending: true,
      muteOpposing: false,
      clearResult: true,
      clearError: true,
    );
    try {
      await _api.end(arg, m.battleId, alternateRoomId: _alternateKey);
      _detachGifts();
      try {
        ref.read(pkBattleRemoteProvider.notifier).clear();
      } catch (_) {}
      state = state.copyWith(ending: false);
    } on ApiException catch (e) {
      // 409 = zaten bitmiş → sorun yok.
      if (e.statusCode == 409) {
        state = state.copyWith(ending: false);
        return;
      }
      _closed.remove(snapshot.battleId);
      state = state.copyWith(match: snapshot, ending: false, error: e.message);
      _syncTicker();
    } catch (_) {
      _closed.remove(snapshot.battleId);
      state = state.copyWith(
        match: snapshot,
        ending: false,
        error: 'PK bitirilemedi, tekrar deneyin',
      );
      _syncTicker();
    }
  }

  // ───────────────────────── Yerel ses ─────────────────────────

  /// Karşı takımın sesini yalnızca BU cihazda kapat/aç (backend'e gitmez).
  void setMuteOpposing(bool mute) {
    if (state.muteOpposing == mute) return;
    state = state.copyWith(muteOpposing: mute);
  }

  void clearResult() {
    if (state.result != null) state = state.copyWith(clearResult: true);
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }

  // ───────────────────────── Hediye kartları ─────────────────────────

  void _attachGifts() {
    if (_giftSub != null) return;
    final service = ref.read(voiceRoomGiftRealtimeProvider);
    _giftSub = service.events.listen(_onGift);
  }

  void _detachGifts() {
    _giftSub?.cancel();
    _giftSub = null;
  }

  void _onGift(LiveGiftEvent e) {
    final m = state.match;
    if (m == null || !m.phase.showsOverlay) return;
    final amount = e.totalCoin > 0 ? e.totalCoin : e.coinCost * e.quantity;
    gifts.add(
      PkGiftToast(
        id: e.id,
        senderName: e.senderName.trim().isEmpty ? 'Birisi' : e.senderName,
        senderAvatarUrl: e.senderAvatar,
        giftName: e.giftName,
        giftImageUrl: e.giftImageUrl ?? e.iconUrl,
        amount: amount,
        quantity: e.quantity,
        side: m.sideOf(e.receiverId),
      ),
    );
  }

  // ───────────────────────── Yaşam döngüsü ─────────────────────────

  /// Odadan çıkış: bütün PK yerel durumu temizlenir (normal oda state'i kirlenmez).
  void reset() {
    _stopTicker();
    _finalizeTimer?.cancel();
    _detachGifts();
    gifts.clear();
    _timeUpHandled.clear();
    state = const PkRoomState();
  }
}

final pkRoomControllerProvider =
    NotifierProvider.family<PkRoomController, PkRoomState, String>(
      PkRoomController.new,
    );

/// Kalan süre dinleyicisi — yalnızca sayaç widget'ı rebuild olur.
final pkRoomRemainingProvider = Provider.family<ValueListenable<int>, String>((
  ref,
  roomKey,
) {
  return ref.watch(pkRoomControllerProvider(roomKey).notifier).remainingSeconds;
});

/// Hediye kartları dinleyicisi.
final pkRoomGiftToastProvider =
    Provider.family<ValueListenable<PkGiftToast?>, String>((ref, roomKey) {
      return ref
          .watch(pkRoomControllerProvider(roomKey).notifier)
          .gifts
          .current;
    });

/// Bu cihazda yerel olarak susturulacak (karşı takım) kullanıcı kimlikleri.
///
/// Yalnızca PK ekranı açıkken ve "karşı takım sessiz" seçiliyken dolu; aksi halde
/// boş küme → herkes normal duyulur. Bu liste yalnızca yerel TRTC oynatmasına
/// uygulanır; hiçbir mikrofon backend'de susturulmaz.
final pkLocalMuteTargetsProvider = Provider.family<Set<String>, String>((
  ref,
  roomKey,
) {
  final s = ref.watch(pkRoomControllerProvider(roomKey));
  final m = s.match;
  if (m == null || !m.phase.showsOverlay || !s.muteOpposing) return const {};
  final myId = ref.watch(authControllerProvider).valueOrNull?.id;
  final mySide = m.sideOf(myId);
  if (mySide == 0) return const {};
  final opposing = mySide == 1 ? 2 : 1;
  return {for (final u in m.team(opposing)) u.userId};
});
