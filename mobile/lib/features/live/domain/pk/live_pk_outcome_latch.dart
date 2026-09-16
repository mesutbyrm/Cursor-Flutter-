/// PK bittiğinde inline rozet metni — aynı battle için flicker önleme.
class LivePkOutcomeLatch {
  String? battleId;
  String? label;

  String resolve({
    required String? currentBattleId,
    required bool ended,
    required String computedLabel,
  }) {
    final bid = currentBattleId?.trim() ?? '';

    if (bid.isNotEmpty && battleId != null && battleId != bid) {
      battleId = null;
      label = null;
    }

    if (ended && bid.isNotEmpty) {
      if (battleId == bid && label != null && label!.isNotEmpty) {
        return label!;
      }
      battleId = bid;
      label = computedLabel;
      return label!;
    }

    if (bid.isNotEmpty && battleId == bid && label != null && label!.isNotEmpty) {
      return label!;
    }

    return computedLabel;
  }
}
