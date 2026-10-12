import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../providers/voice_room_session_registry.dart';
import 'voice_room_leave_flow.dart';

/// `/voice-room/:id` yolundan oda kimliği (slug veya api anahtarı).
String? voiceRoomRouteIdFromLocations(Iterable<String> locations) {
  for (final raw in locations) {
    final loc = raw.trim();
    if (loc.isEmpty || loc == '/voice-room') continue;
    if (!loc.startsWith('/voice-room/')) continue;
    final rest = loc.substring('/voice-room/'.length);
    final id = rest.split('/').first.trim();
    if (id.isNotEmpty) return id;
  }
  return null;
}

/// Ön plana dönüşte hangi [voiceRoomLiveProvider] ailesinin iyileştirileceği.
String? resolveForegroundVoiceRoomLiveKey(WidgetRef ref) {
  final active = ref.read(voiceRoomActiveLiveKeyProvider)?.trim();
  if (active != null && active.isNotEmpty) return active;

  final pending = ref.read(voiceRoomPendingLiveKeyProvider)?.trim();
  if (pending != null && pending.isNotEmpty) return pending;

  try {
    final router = ref.read(goRouterProvider);
    final config = router.routerDelegate.currentConfiguration;
    final paths = <String>[
      config.uri.path,
      for (final m in config.matches) m.matchedLocation,
    ];
    if (!VoiceRoomLeaveFlow.voiceRoomInStack(paths)) return null;
    return voiceRoomRouteIdFromLocations(paths);
  } catch (_) {
    return null;
  }
}
