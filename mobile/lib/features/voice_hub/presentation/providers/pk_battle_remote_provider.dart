import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/pk_battle_remote_datasource.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import 'pk_battle_provider.dart';

final pkBattleRemoteDataSourceProvider = Provider<PkBattleRemoteDataSource>((ref) {
  return PkBattleRemoteDataSource(ref.watch(dioProvider));
});

/// Sunucu PK senkronu — REST.
///
/// ÖNEMLİ MİMARİ DEĞİŞİKLİK: PK battle artık kendi Socket.IO/SSE
/// bağlantısını AÇMIYOR. Backend resmi sözleşmesi PK olaylarını voice
/// room'un zaten açık olan tek SSE akışı üzerinden (`"type": "pk"`)
/// yayınlıyor. Canlı güncellemeler artık `chat_room_providers.dart`
/// içindeki `_startSse()`'in `onPk` callback'i üzerinden doğrudan
/// `pkBattleProvider.applyRemoteBattle()`'a yönlendiriliyor — bkz.
/// `voice_room_sse_provider.dart` / `voiceRoomSseServiceProvider`.
///
/// Bu controller artık sadece:
///  - REST ile PK aksiyonlarını tetikler (invite/accept/reject/end)
///  - REST ile mevcut battle durumunu yükler (loadRoomBattle/loadStreamBattle)
///  - Kendi `state`'ini (PkBattleRemote?) bu REST çağrılarına göre tutar
///
/// `connectSocket`/`disconnectSocket` metodları, çağıran widget kodu
/// değişmeden çalışmaya devam etsin diye **no-op** olarak bırakıldı.
/// Yeni kodda bunları çağırmaya gerek yoktur; canlı yayın (streamId ile,
/// oda bağlamı olmayan) PK senaryosu için ayrıca bkz. not en altta.
class PkBattleRemoteController extends Notifier<PkBattleRemote?> {
  PkBattleRemoteDataSource get _api => ref.read(pkBattleRemoteDataSourceProvider);

  @override
  PkBattleRemote? build() => null;

  Future<PkBattleRemote?> loadRoomBattle(String roomId, {String? alternateRoomId}) async {
    final battle = await _api.fetchRoomBattle(
      roomId,
      alternateRoomId: alternateRoomId,
    );
    if (battle != null) _apply(battle, 'load');
    return battle;
  }

  /// Sunucudaki askıda / bitmemiş PK kaydını temizler; davet öncesi çağırın.
  Future<bool> prepareRoomForInvite({
    required String roomId,
    String? alternateRoomId,
  }) async {
    final stale = state;
    if (stale != null && stale.isEnded) clear();

    final battle = await _api.fetchRoomBattle(
      roomId,
      alternateRoomId: alternateRoomId,
    );
    if (battle == null) {
      clear();
      return true;
    }
    if (battle.isEnded) {
      clear();
      return true;
    }
    if (battle.id.isEmpty) {
      clear();
      return true;
    }
    try {
      await end(
        battle.id,
        roomId: roomId,
        alternateRoomId: alternateRoomId,
      );
    } catch (_) {}
    clear();
    return true;
  }

  Future<PkBattleRemote?> loadStreamBattle(String streamId) async {
    final battle = await _api.fetchStreamBattle(streamId);
    if (battle != null) _apply(battle, 'load');
    return battle;
  }

  Future<PkBattleRemote?> inviteRoom({
    required String roomId,
    String? alternateRoomId,
    required String opponentRoomId,
    String? alternateOpponentRoomId,
    int durationSeconds = 180,
  }) async {
    final stale = state;
    if (stale != null && stale.isEnded) clear();

    final battle = await _api.inviteVoiceRoom(
      roomId: roomId,
      alternateRoomId: alternateRoomId,
      opponentRoomId: opponentRoomId,
      alternateOpponentRoomId: alternateOpponentRoomId,
      durationSeconds: durationSeconds,
    );
    if (battle != null) _apply(battle, 'pk:invite');
    return battle;
  }

  Future<PkBattleRemote?> inviteStream({
    required String streamId,
    required String opponentStreamId,
  }) async {
    final battle = await _api.streamPkAction(
      streamId: streamId,
      action: 'create',
      opponentStreamId: opponentStreamId,
    );
    if (battle != null) _apply(battle, 'pk:invite');
    return battle;
  }

  /// Sesli oda: `roomId` zorunlu. Canlı yayın: `streamId` verin.
  Future<PkBattleRemote?> accept(
    String battleId, {
    String? roomId,
    String? alternateRoomId,
    String? streamId,
  }) async {
    final PkBattleRemote? battle;
    if (roomId != null && roomId.trim().isNotEmpty) {
      battle = await _api.acceptBattle(
        battleId,
        roomId: roomId,
        alternateRoomId: alternateRoomId,
      );
    } else if (streamId != null && streamId.trim().isNotEmpty) {
      battle = await _api.streamPkAction(
        streamId: streamId,
        action: 'accept',
        battleId: battleId,
      );
    } else {
      return null;
    }
    if (battle != null) _apply(battle, 'pk:accept');
    return battle;
  }

  Future<PkBattleRemote?> reject(
    String battleId, {
    String? roomId,
    String? alternateRoomId,
    String? streamId,
  }) async {
    final PkBattleRemote? battle;
    if (roomId != null && roomId.trim().isNotEmpty) {
      battle = await _api.rejectBattle(
        battleId,
        roomId: roomId,
        alternateRoomId: alternateRoomId,
      );
    } else if (streamId != null && streamId.trim().isNotEmpty) {
      battle = await _api.streamPkAction(
        streamId: streamId,
        action: 'reject',
        battleId: battleId,
      );
    } else {
      return null;
    }
    if (battle != null) _apply(battle, 'pk:reject');
    return battle;
  }

  Future<PkBattleRemote?> end(
    String battleId, {
    String? roomId,
    String? alternateRoomId,
    String? streamId,
  }) async {
    final PkBattleRemote? battle;
    if (roomId != null && roomId.trim().isNotEmpty) {
      battle = await _api.endBattle(
        battleId,
        roomId: roomId,
        alternateRoomId: alternateRoomId,
      );
    } else if (streamId != null && streamId.trim().isNotEmpty) {
      battle = await _api.streamPkAction(
        streamId: streamId,
        action: 'end',
        battleId: battleId,
      );
    } else {
      return null;
    }
    if (battle != null) _apply(battle, 'pk:end');
    return battle;
  }

  /// @deprecated Artık no-op. PK canlı güncellemeleri voice room'un ana
  /// SSE akışı üzerinden otomatik gelir (bkz. sınıf dokümantasyonu).
  /// Geriye dönük uyumluluk için tutuldu; yeni kodda çağırmayın.
  void connectSocket({
    String? roomId,
    String? alternateRoomId,
    String? streamId,
    String? battleId,
  }) {
    // Bilinçli olarak boş bırakıldı. Oda bağlamındaki (roomId verilen)
    // PK battle'lar artık chat_room_providers.dart → _startSse() → onPk
    // üzerinden otomatik beslenir.
    //
    // NOT: streamId ile, oda bağlamı OLMADAN açılan canlı yayın PK'leri
    // (voice room dışı) için ayrı bir SSE aboneliği gerekiyorsa, bu
    // canlı yayının kendi stream SSE servisinde de aynı şekilde bir
    // `onPk` eklenmesi gerekir — bu henüz yapılmadı, bkz. TODO.
  }

  /// @deprecated Artık no-op.
  void disconnectSocket() {}

  void _apply(PkBattleRemote battle, String event) {
    state = battle;
    ref.read(pkBattleProvider.notifier).applyRemoteBattle(battle);
  }

  void clear() {
    state = null;
  }
}

final pkBattleRemoteProvider =
    NotifierProvider<PkBattleRemoteController, PkBattleRemote?>(
  PkBattleRemoteController.new,
);

/// PK geçmişi listesi.
final pkHistoryProvider =
    FutureProvider.family<List<PkBattleRemote>, String?>((ref, battleType) async {
  final api = ref.watch(pkBattleRemoteDataSourceProvider);
  return api.fetchHistory(battleType: battleType);
});
