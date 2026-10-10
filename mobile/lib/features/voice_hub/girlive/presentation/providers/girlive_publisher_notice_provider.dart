import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SSE `girlive_publisher` — yalnızca hedef yayıncıya özel satır (sohbete yazılmaz).
class GirLivePublisherNotice {
  const GirLivePublisherNotice({
    required this.text,
    required this.nonce,
    required this.roomKey,
    this.kind,
  });

  final String text;
  final int nonce;
  final String roomKey;
  final String? kind;
}

class GirLivePublisherNoticeNotifier extends Notifier<GirLivePublisherNotice?> {
  var _nonce = 0;

  @override
  GirLivePublisherNotice? build() => null;

  void show(String text, {required String roomKey, String? kind}) {
    final t = text.trim();
    if (t.isEmpty) return;
    _nonce++;
    state = GirLivePublisherNotice(
      text: t,
      nonce: _nonce,
      roomKey: roomKey.trim(),
      kind: kind,
    );
  }

  void clear() => state = null;
}

final girLivePublisherNoticeProvider =
    NotifierProvider<GirLivePublisherNoticeNotifier, GirLivePublisherNotice?>(
  GirLivePublisherNoticeNotifier.new,
);
