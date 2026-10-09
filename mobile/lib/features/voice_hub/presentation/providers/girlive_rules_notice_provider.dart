import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// GirLive Bot — odaya girene yönelik kural/duyuru hatırlatması
/// (`girlive_rules` oda olayı). Yalnızca hedef kullanıcının sohbet ekranında,
/// bot satırı olarak gösterilir ([visibleFor] sonra kendiliğinden kalkar);
/// herkese açık sohbete yazılmaz, popup değildir.
class GirLiveRulesNotice {
  const GirLiveRulesNotice({
    required this.text,
    required this.nonce,
    this.roomKey,
  });
  final String text;
  final int nonce;

  /// Olayın geldiği oda; başka bir odanın sohbetinde gösterilmez.
  final String? roomKey;

  bool belongsTo(String roomKey) {
    final k = this.roomKey?.trim() ?? '';
    return k.isEmpty || k == roomKey.trim();
  }
}

class GirLiveRulesNoticeNotifier extends Notifier<GirLiveRulesNotice?> {
  /// Kural satırı sohbette bu süre kalır.
  static const visibleFor = Duration(seconds: 15);

  var _seq = 0;
  Timer? _hide;

  @override
  GirLiveRulesNotice? build() {
    ref.onDispose(() => _hide?.cancel());
    return null;
  }

  void show(String text, {String? roomKey}) {
    final t = text.trim();
    if (t.isEmpty) return;
    final nonce = ++_seq;
    state = GirLiveRulesNotice(text: t, nonce: nonce, roomKey: roomKey);
    _hide?.cancel();
    _hide = Timer(visibleFor, () {
      if (state?.nonce == nonce) state = null;
    });
  }

  void clear() {
    _hide?.cancel();
    state = null;
  }
}

final girLiveRulesNoticeProvider =
    NotifierProvider<GirLiveRulesNoticeNotifier, GirLiveRulesNotice?>(
  GirLiveRulesNoticeNotifier.new,
);
