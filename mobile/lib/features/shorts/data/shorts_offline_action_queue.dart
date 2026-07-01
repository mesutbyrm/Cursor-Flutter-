import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/connectivity/connectivity_service.dart';

enum ShortOfflineActionType { like, save, follow }

class ShortOfflineAction {
  const ShortOfflineAction({
    required this.type,
    required this.targetId,
    required this.createdAtMs,
    this.liked = true,
  });

  final ShortOfflineActionType type;
  final String targetId;
  final int createdAtMs;
  final bool liked;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'targetId': targetId,
        'createdAtMs': createdAtMs,
        'liked': liked,
      };

  factory ShortOfflineAction.fromJson(Map<String, dynamic> json) {
    return ShortOfflineAction(
      type: ShortOfflineActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ShortOfflineActionType.like,
      ),
      targetId: (json['targetId'] ?? '').toString(),
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      liked: json['liked'] != false,
    );
  }
}

/// Beğeni / kaydet / takip — çevrimdışı kuyruk; bağlantı gelince senkronize.
class ShortsOfflineActionQueue {
  ShortsOfflineActionQueue._();

  static const _key = 'shorts_offline_actions_v1';
  static final instance = ShortsOfflineActionQueue._();

  var _flushing = false;

  Future<void> enqueueLike(String videoId, {required bool liked}) =>
      _enqueue(
        ShortOfflineAction(
          type: ShortOfflineActionType.like,
          targetId: videoId,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          liked: liked,
        ),
      );

  Future<void> enqueueSave(String videoId, {required bool saved}) => _enqueue(
        ShortOfflineAction(
          type: ShortOfflineActionType.save,
          targetId: videoId,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          liked: saved,
        ),
      );

  Future<List<ShortOfflineAction>> pending() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => ShortOfflineAction.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _enqueue(ShortOfflineAction action) async {
    final list = await pending();
    final next = [
      ...list.where((a) =>
          !(a.type == action.type && a.targetId == action.targetId)),
      action,
    ];
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(next.map((e) => e.toJson()).toList()));
  }

  Future<void> flush({
    required Future<void> Function(ShortOfflineAction action) onAction,
  }) async {
    if (_flushing) return;
    _flushing = true;
    try {
      final online = ConnectivityService().isOnline;
      if (!online) return;
      final list = await pending();
      if (list.isEmpty) return;
      final remaining = <ShortOfflineAction>[];
      for (final action in list) {
        try {
          await onAction(action);
        } catch (_) {
          remaining.add(action);
        }
      }
      final p = await SharedPreferences.getInstance();
      if (remaining.isEmpty) {
        await p.remove(_key);
      } else {
        await p.setString(
          _key,
          jsonEncode(remaining.map((e) => e.toJson()).toList()),
        );
      }
    } finally {
      _flushing = false;
    }
  }
}
