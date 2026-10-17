import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/dj_request_remote_datasource.dart';
import '../../domain/entities/dj_request.dart';

final djRequestRemoteProvider = Provider<DjRequestRemoteDataSource>(
  (ref) => DjRequestRemoteDataSource(ref.watch(dioProvider)),
);

/// Odanın DJ istekleri (!istek). SSE DJ olayındaki `djRequests` ile anında,
/// ayrıca 15 sn'de bir sunucudan güncellenir (süre aşımı iadeleri de böyle
/// tetiklenir).
final voiceRoomDjRequestsProvider = NotifierProvider.autoDispose
    .family<VoiceRoomDjRequestsController, DjRequestsSnapshot, String>(
  VoiceRoomDjRequestsController.new,
);

class VoiceRoomDjRequestsController
    extends AutoDisposeFamilyNotifier<DjRequestsSnapshot, String> {
  Timer? _poll;
  var _busy = false;

  String get _roomKey => arg;

  @override
  DjRequestsSnapshot build(String roomKey) {
    _poll?.cancel();
    if (roomKey.isNotEmpty) {
      _poll = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
      Future<void>.microtask(refresh);
    }
    ref.onDispose(() => _poll?.cancel());
    return const DjRequestsSnapshot();
  }

  Future<void> refresh() async {
    if (_roomKey.isEmpty || _busy) return;
    _busy = true;
    try {
      state = await ref.read(djRequestRemoteProvider).fetch(_roomKey);
    } catch (_) {
      // Ağ hatası: mevcut durum korunur, sonraki turda yeniden denenir.
    } finally {
      _busy = false;
    }
  }

  /// SSE DJ yükündeki `djRequests` alanı.
  void applyDjPayload(Map<String, dynamic> payload) {
    final raw = payload['djRequests'] ??
        (payload['data'] is Map ? (payload['data'] as Map)['djRequests'] : null);
    if (raw is Map) state = DjRequestsSnapshot.fromJson(raw);
  }

  /// Hata mesajı ya da `null`.
  Future<String?> create(String query) async {
    try {
      await ref.read(djRequestRemoteProvider).create(_roomKey, query);
      unawaited(refresh());
      return null;
    } catch (e) {
      return _message(e, 'İstek gönderilemedi');
    }
  }

  /// [action]: play | reject | cancel | done — hata mesajı ya da `null`.
  Future<String?> act(String requestId, String action) async {
    try {
      await ref.read(djRequestRemoteProvider).act(_roomKey, requestId, action);
      unawaited(refresh());
      return null;
    } catch (e) {
      return _message(e, 'İşlem yapılamadı');
    }
  }

  static String _message(Object e, String fallback) {
    if (e is ApiException && e.message.trim().isNotEmpty) return e.message;
    return fallback;
  }
}
