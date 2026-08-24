/// `/voice-room/:id` yolundan canlı oda anahtarını çıkarır.
String? voiceRoomLiveKeyFromPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return null;
  final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  final uri = Uri.tryParse(normalized);
  if (uri == null) return null;
  final segments = uri.pathSegments;
  if (segments.isEmpty || segments.first != 'voice-room') return null;
  if (segments.length < 2) return null;
  final id = segments[1].trim();
  return id.isEmpty ? null : id;
}

bool isVoiceRoomNavigationPath(String path) =>
    voiceRoomLiveKeyFromPath(path) != null;
