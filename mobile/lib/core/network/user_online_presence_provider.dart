import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_endpoints.dart';
import 'dio_provider.dart';
import 'user_presence_service.dart';
import '../bootstrap/session_data_refresh.dart';

/// Site geneli çevrimiçi kullanıcı kimlikleri — `GET /api/users/online`.
class UserOnlinePresenceNotifier extends Notifier<Set<String>> {
  Timer? _heartbeatTimer;
  Timer? _refreshTimer;

  static const _heartbeatInterval = Duration(seconds: 60);
  static const _refreshInterval = Duration(seconds: 45);

  @override
  Set<String> build() {
    ref.onDispose(_stopTimers);
    Future.microtask(_bootstrap);
    return const {};
  }

  void _stopTimers() {
    _heartbeatTimer?.cancel();
    _refreshTimer?.cancel();
    _heartbeatTimer = null;
    _refreshTimer = null;
  }

  Future<void> _bootstrap() async {
    await _sendHeartbeat();
    await refresh();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      unawaited(_sendHeartbeat());
    });
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      unawaited(refresh());
    });
  }

  Future<void> _sendHeartbeat() async {
    await ref.read(userPresenceServiceProvider).heartbeat();
  }

  Future<void> refresh() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.safeGet<dynamic>(ApiEndpoints.usersOnline);
      final ids = parseOnlineUserIds(res.data);
      state = ids;
    } catch (_) {}
  }

  Future<void> leave() async {
    _stopTimers();
    await ref.read(userPresenceServiceProvider).leave();
    state = const {};
  }

  bool isUserOnline(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return false;
    return state.contains(id);
  }
}

Set<String> parseOnlineUserIds(dynamic raw) {
  if (raw == null) return {};
  if (raw is List) {
    return {
      for (final item in raw)
        if (_extractUserId(item) != null) _extractUserId(item)!,
    };
  }
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final list =
        map['users'] ?? map['online'] ?? map['onlineUsers'] ?? map['data'];
    if (list is List) {
      return {
        for (final item in list)
          if (_extractUserId(item) != null) _extractUserId(item)!,
      };
    }
    final ids = map['userIds'] ?? map['ids'];
    if (ids is List) {
      return {
        for (final id in ids)
          if ('$id'.trim().isNotEmpty) '$id'.trim(),
      };
    }
  }
  return {};
}

String? _extractUserId(dynamic item) {
  if (item == null) return null;
  if (item is String) {
    final s = item.trim();
    return s.isEmpty ? null : s;
  }
  if (item is Map) {
    final map = Map<String, dynamic>.from(item);
    final id = map['id'] ?? map['userId'] ?? map['user_id'];
    final s = id?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }
  return null;
}

final userOnlinePresenceProvider =
    NotifierProvider<UserOnlinePresenceNotifier, Set<String>>(
  UserOnlinePresenceNotifier.new,
);

/// Arkadaş/takip listelerinde yeşil nokta — oturum + lifecycle ile senkron.
class UserOnlinePresenceLifecycleHost extends ConsumerStatefulWidget {
  const UserOnlinePresenceLifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UserOnlinePresenceLifecycleHost> createState() =>
      _UserOnlinePresenceLifecycleHostState();
}

class _UserOnlinePresenceLifecycleHostState
    extends ConsumerState<UserOnlinePresenceLifecycleHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(userOnlinePresenceProvider.notifier).refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(userOnlinePresenceProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(notifier.refresh());
        unawaited(ref.read(userPresenceServiceProvider).heartbeat());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(ref.read(userPresenceServiceProvider).leave());
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
