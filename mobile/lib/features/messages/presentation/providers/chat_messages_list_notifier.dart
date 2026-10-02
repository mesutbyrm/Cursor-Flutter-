import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/message_entities.dart';
import '../../domain/utils/dm_message_codec.dart';
import '../../domain/utils/dm_message_merge.dart';
import '../../data/services/message_sse_service.dart';
import 'messages_providers.dart';

/// Sohbet: en yeni mesajlar önce gösterilir; yukarı kaydırınca eski mesajlar yüklenir.
class ChatMessagesListState {
  const ChatMessagesListState({
    required this.all,
    this.visibleCount = ListPerf.defaultPageSize,
  });

  final List<MessageEntity> all;
  final int visibleCount;

  bool get hasMore => visibleCount < all.length;

  List<MessageEntity> get visible {
    if (all.isEmpty) return const [];
    final start = (all.length - visibleCount).clamp(0, all.length);
    return all.sublist(start);
  }

  int get olderHiddenCount => all.length - visible.length;

  ChatMessagesListState copyWith({
    List<MessageEntity>? all,
    int? visibleCount,
  }) {
    return ChatMessagesListState(
      all: all ?? this.all,
      visibleCount: visibleCount ?? this.visibleCount,
    );
  }
}

class ChatMessagesListNotifier
    extends FamilyAsyncNotifier<ChatMessagesListState, String> {
  /// Eşzamanlı yenilemelerde yalnızca en yenisi uygulanır (sıra bozuk yanıt
  /// ekranı eski listeyle ezmesin).
  var _refreshSeq = 0;

  @override
  Future<ChatMessagesListState> build(String conversationId) async {
    final remote = await _fetchRemote(conversationId, forceRefresh: false);
    return _compose(remote, previous: null);
  }

  Future<List<MessageEntity>> _fetchRemote(
    String conversationId, {
    required bool forceRefresh,
  }) {
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    return ref.read(messagesRepositoryProvider).messages(
          conversationId,
          currentUserId: userId,
          forceRefresh: forceRefresh,
        );
  }

  /// Sunucu listesi + ekrandaki liste → kimliğe göre birleşik durum.
  /// [previous] işlem SONUNDA (commit anında) okunan güncel durumdur.
  ChatMessagesListState _compose(
    List<MessageEntity> remote, {
    required ChatMessagesListState? previous,
  }) {
    var all = DmMessageMerge.mergeById(
      previous: previous?.all ?? const <MessageEntity>[],
      remote: remote,
    );
    all = all.where((m) {
      final note = DmMessageCodec.parseVoiceNote(m.text);
      if (note == null) return true;
      return !DmMessageCodec.isExpiredVoiceNote(note);
    }).toList();
    return ChatMessagesListState(all: all, visibleCount: all.length);
  }

  Future<void> refresh({
    bool silent = false,
    bool forceRefresh = true,
  }) async {
    final id = arg;
    final seq = ++_refreshSeq;
    if (!silent) {
      state = const AsyncLoading<ChatMessagesListState>().copyWithPrevious(state);
    }
    ref.invalidate(chatMessagesProvider(id));
    try {
      final remote = await _fetchRemote(id, forceRefresh: forceRefresh);
      if (seq != _refreshSeq) return; // daha yeni bir yenileme başladı
      // ÖNEMLİ: birleştirme commit anındaki güncel duruma göre yapılır —
      // yenileme sürerken eklenen optimistic mesaj ezilmez.
      state = AsyncValue.data(_compose(remote, previous: state.valueOrNull));
    } catch (e, st) {
      if (seq != _refreshSeq) return;
      // Sessiz yenileme hata verirse ekrandaki mesajlar KORUNUR.
      if (silent && state.valueOrNull != null) return;
      state = AsyncValue.error(e, st);
    }
  }

  void loadOlder() {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore) return;
    state = AsyncValue.data(
      cur.copyWith(
        visibleCount: (cur.visibleCount + ListPerf.defaultPageSize)
            .clamp(0, cur.all.length),
      ),
    );
  }

  Future<void> deleteMessage(String messageId) async {
    if (messageId.isEmpty) return;
    final cur = state.valueOrNull;
    if (cur != null) {
      state = AsyncValue.data(
        cur.copyWith(
          all: cur.all.where((m) => m.id != messageId).toList(),
        ),
      );
    }
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    try {
      await ref.read(messagesRepositoryProvider).deleteMessage(
            arg,
            messageId,
            currentUserId: userId,
          );
    } catch (_) {}
  }

  void ingestFromSse(MessageSseEvent event, {required String? currentUserId}) {
    final content = event.content?.trim();
    if (content == null || content.isEmpty) return;
    final id = event.messageId?.trim();
    if (id != null && id.isNotEmpty) {
      final cur = state.valueOrNull;
      if (cur != null && cur.all.any((m) => m.id == id)) return;
    }
    final uid = currentUserId ?? '';
    final sender = event.senderId?.trim() ?? '';
    final isMine = sender.isNotEmpty && uid.isNotEmpty && sender == uid;
    final parsed = DmMessageCodec.parseDisplay(content);
    final entity = MessageEntity(
      id: id?.isNotEmpty == true ? id! : 'sse-${DateTime.now().microsecondsSinceEpoch}',
      text: parsed.displayText,
      isMine: isMine,
      createdAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.delivered,
      replyTo: parsed.reply,
      forwardedFrom: parsed.forwardedFrom,
      rawText: content,
    );
    final cur = state.valueOrNull;
    if (cur == null) {
      state = AsyncValue.data(
        ChatMessagesListState(all: [entity], visibleCount: 1),
      );
      return;
    }
    // SSE'den gelen mesaj = sunucu kaydı: eşleşen optimistic mesajın yerini alır.
    final merged = DmMessageMerge.upsert(cur.all, entity);
    state = AsyncValue.data(
      cur.copyWith(all: merged, visibleCount: merged.length),
    );
  }

  void _markLocalOptimisticDelivered(String optimisticId) {
    final latest = state.valueOrNull;
    if (latest == null) return;
    var touched = false;
    final all = latest.all.map((m) {
      if (m.id != optimisticId) return m;
      touched = true;
      return MessageEntity(
        id: m.id,
        text: m.text,
        isMine: m.isMine,
        createdAt: m.createdAt,
        deliveryStatus: MessageDeliveryStatus.delivered,
        replyTo: m.replyTo,
        forwardedFrom: m.forwardedFrom,
        rawText: m.rawText,
      );
    }).toList();
    if (!touched) return;
    state = AsyncValue.data(latest.copyWith(all: all));
  }

  Future<void> sendMessage({
    required String text,
    String? currentUserId,
    String? replyId,
    String? replyText,
    bool forward = false,
    String? forwardFrom,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final optimisticId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final cur = state.valueOrNull;
    final optimistic = MessageEntity(
      id: optimisticId,
      text: trimmed,
      isMine: true,
      createdAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.sending,
      replyTo: replyId != null && replyText != null
          ? DmReplyMeta(id: replyId, text: replyText)
          : null,
      forwardedFrom: forward ? (forwardFrom ?? 'İletilen mesaj') : null,
    );
    if (cur != null) {
      state = AsyncValue.data(
        cur.copyWith(
          all: [...cur.all, optimistic],
          visibleCount: cur.visibleCount + 1,
        ),
      );
    }
    try {
      await ref.read(messagesRepositoryProvider).sendMessage(
            arg,
            trimmed,
            currentUserId: currentUserId,
            replyId: replyId,
            replyText: replyText,
            forward: forward,
            forwardFrom: forwardFrom,
          );
      _markLocalOptimisticDelivered(optimisticId);
      await refresh(silent: true, forceRefresh: true);
      _markLocalOptimisticDelivered(optimisticId);
    } on ApiException catch (e) {
      if (e.statusCode == 403 &&
          e.message.toLowerCase().contains('mesaj iste')) {
        _markLocalOptimisticDelivered(optimisticId);
        return;
      }
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncValue.data(
          latest.copyWith(
            all: latest.all.where((m) => m.id != optimisticId).toList(),
          ),
        );
      }
      rethrow;
    } catch (e, st) {
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncValue.data(
          latest.copyWith(
            all: latest.all.where((m) => m.id != optimisticId).toList(),
          ),
        );
      }
      Error.throwWithStackTrace(e, st);
    }
  }
}

final chatMessagesListNotifierProvider = AsyncNotifierProvider.family<
    ChatMessagesListNotifier, ChatMessagesListState, String>(
  ChatMessagesListNotifier.new,
);
