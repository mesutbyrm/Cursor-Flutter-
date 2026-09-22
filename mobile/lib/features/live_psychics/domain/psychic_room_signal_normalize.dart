import 'dart:convert';

/// `/api/room/signal` — üretim `signalType` / `signalData`, kılavuz `type` / `data`.
Map<String, dynamic> normalizePsychicRoomSignalMap(Map<String, dynamic> raw) {
  final out = Map<String, dynamic>.from(raw);

  final type = (out['type'] ?? out['signalType'] ?? '').toString().trim();
  if (type.isNotEmpty) {
    out['type'] = type;
    out['signalType'] = type;
  }

  dynamic dataRaw = out['data'] ?? out['signalData'];
  if (dataRaw is String) {
    final trimmed = dataRaw.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        dataRaw = jsonDecode(trimmed);
      } catch (_) {}
    }
  }
  if (dataRaw is Map) {
    final data = Map<String, dynamic>.from(dataRaw);
    out['data'] = data;
    out['signalData'] = data;
  }

  final payload = out['payload'];
  if (payload is Map && out['data'] == null) {
    final p = Map<String, dynamic>.from(payload);
    out['data'] = p;
    if (type.isEmpty) {
      final fromPayload = (p['type'] ?? p['action'] ?? p['signalType'] ?? '')
          .toString()
          .trim();
      if (fromPayload.isNotEmpty) {
        out['type'] = fromPayload;
        out['signalType'] = fromPayload;
      }
    }
  }

  return out;
}

bool isPsychicTimerHandshakeSignalType(String? raw) {
  final t = (raw ?? '').trim().toLowerCase();
  return t == 'timer_start_request' ||
      t == 'timer_start_accept' ||
      t.contains('timer_start_request') ||
      t.contains('timer_start_accept');
}
