/// PK sırasında paylaşılan canlı sohbet — challenger (host) yayın odası.
String resolveLivePkChatStreamId(Map<String, dynamic>? battle) {
  final b = battle ?? const <String, dynamic>{};
  final host = (b['liveStreamId'] ??
          b['hostStreamId'] ??
          b['streamId'])
      ?.toString()
      .trim();
  if (host != null && host.isNotEmpty) return host;
  final opponent = (b['opponentLiveStreamId'] ??
          b['opponentStreamId'] ??
          b['targetStreamId'])
      ?.toString()
      .trim();
  return opponent ?? '';
}

/// Mesaj gönderimi / SSE için kullanılacak oda (PK'da her iki yayıncı aynı oda).
String livePkEffectiveChatStreamId({
  required Map<String, dynamic>? battle,
  required String myStreamId,
}) {
  final unified = resolveLivePkChatStreamId(battle);
  if (unified.isNotEmpty) return unified;
  return myStreamId.trim();
}
