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

/// Mesaj gönderimi / SSE için kullanılacak oda.
///
/// PK'da her yayının sohbeti ayrıdır: A'yı izleyen yalnız A'nın sohbetini,
/// B'yi izleyen yalnız B'nin sohbetini görür ve oraya yazar. (Önceden iki
/// taraf da challenger'ın odasına yönlendiriliyordu.) İzlenen yayın kimliği
/// boşsa eski davranışa düşülür.
String livePkEffectiveChatStreamId({
  required Map<String, dynamic>? battle,
  required String myStreamId,
}) {
  final mine = myStreamId.trim();
  if (mine.isNotEmpty) return mine;
  return resolveLivePkChatStreamId(battle);
}
