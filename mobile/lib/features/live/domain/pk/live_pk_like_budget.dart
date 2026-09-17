/// PK beğeni — kullanıcı başına en fazla 3 puan (istemci; backend authoritative).
class LivePkLikeBudget {
  LivePkLikeBudget({this.maxPoints = 3});

  final int maxPoints;
  final _spent = <String, int>{};

  String _key(String pkId, String userId) => '${pkId.trim()}|${userId.trim()}';

  bool canAward(String pkId, String userId, int amount) {
    if (pkId.trim().isEmpty || userId.trim().isEmpty) return false;
    final used = _spent[_key(pkId, userId)] ?? 0;
    return used + amount <= maxPoints;
  }

  void record(String pkId, String userId, int amount) {
    if (amount <= 0) return;
    final k = _key(pkId, userId);
    _spent[k] = (_spent[k] ?? 0) + amount;
  }

  int remaining(String pkId, String userId) {
    final used = _spent[_key(pkId, userId)] ?? 0;
    return (maxPoints - used).clamp(0, maxPoints);
  }
}
