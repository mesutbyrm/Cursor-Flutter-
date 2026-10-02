import 'package:flutter_riverpod/flutter_riverpod.dart';

/// GirLive Bot — odaya girene yönelik kural hatırlatması (`girlive_rules` oda
/// olayı). Yalnızca hedef kullanıcıda gösterilir; herkese açık sohbete yazılmaz.
class GirLiveRulesNotice {
  const GirLiveRulesNotice({required this.text, required this.nonce});
  final String text;
  final int nonce;
}

class GirLiveRulesNoticeNotifier extends Notifier<GirLiveRulesNotice?> {
  var _seq = 0;

  @override
  GirLiveRulesNotice? build() => null;

  void show(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    state = GirLiveRulesNotice(text: t, nonce: ++_seq);
  }
}

final girLiveRulesNoticeProvider =
    NotifierProvider<GirLiveRulesNoticeNotifier, GirLiveRulesNotice?>(
  GirLiveRulesNoticeNotifier.new,
);
