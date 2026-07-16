import '../entities/live_stream_entity.dart';

/// PK için uygun canlı yayın — cache yok; tek kaynak filtre kuralları.
List<LiveStreamEntity> filterPkEligibleLiveStreams(
  List<LiveStreamEntity> streams, {
  String? excludeStreamId,
}) {
  final exclude = excludeStreamId?.trim() ?? '';
  final seen = <String>{};
  final out = <LiveStreamEntity>[];

  for (final s in streams) {
    if (!isPkEligibleLiveStream(s, excludeStreamId: exclude)) continue;
    final key = s.id.trim();
    if (key.isEmpty || seen.contains(key)) continue;
    seen.add(key);
    out.add(s);
  }

  out.sort((a, b) => b.viewerCount.compareTo(a.viewerCount));
  return out;
}

bool isPkEligibleLiveStream(
  LiveStreamEntity stream, {
  required String excludeStreamId,
}) {
  final id = stream.id.trim();
  if (id.isEmpty) return false;
  if (excludeStreamId.isNotEmpty && id == excludeStreamId) return false;
  if (!stream.isLive) return false;

  final host = stream.hostUserId?.trim() ?? '';
  if (host.isEmpty) return false;

  // İzleyicisi olan veya aktif PK'da olan yayınlar.
  if (stream.viewerCount <= 0 && !stream.isPkLive) return false;

  return true;
}
