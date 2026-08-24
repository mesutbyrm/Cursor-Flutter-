/// SSE / REST müzik olaylarında aynı parçanın iki kez oynatılmasını engeller.
class RoomMusicPlaybackDedupe {
  String? _lastTrackKey;
  String? _lastEventId;

  /// `true` dönerse oynatma atlanabilir (duplicate).
  bool isDuplicate({
    String? trackKey,
    String? eventId,
    String? queueId,
    String? videoId,
    String? streamUrl,
  }) {
    final key = trackKey ??
        _composeKey(
          eventId: eventId,
          queueId: queueId,
          videoId: videoId,
          streamUrl: streamUrl,
        );
    if (key.isEmpty) return false;
    if (_lastTrackKey == key) return true;
    if (eventId != null &&
        eventId.isNotEmpty &&
        _lastEventId == eventId) {
      return true;
    }
    _lastTrackKey = key;
    if (eventId != null && eventId.isNotEmpty) {
      _lastEventId = eventId;
    }
    return false;
  }

  void clear() {
    _lastTrackKey = null;
    _lastEventId = null;
  }

  static String _composeKey({
    String? eventId,
    String? queueId,
    String? videoId,
    String? streamUrl,
  }) {
    if (queueId != null && queueId.isNotEmpty) return 'q:$queueId';
    if (eventId != null && eventId.isNotEmpty) return 'e:$eventId';
    final url = streamUrl?.trim() ?? '';
    if (url.isNotEmpty) return 'u:$url';
    final vid = videoId?.trim() ?? '';
    if (vid.isNotEmpty) return 'v:$vid';
    return '';
  }
}
