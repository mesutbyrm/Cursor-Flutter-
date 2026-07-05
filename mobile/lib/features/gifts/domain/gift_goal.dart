import '../../../core/util/json_util.dart';

/// Hediye hedefi — bir bağlamda (oda/yayın) toplanan jetonun bir eşiğe
/// ulaşma ilerlemesini tutar. Eşik dolunca kutlama tetiklenir.
class GiftGoal {
  const GiftGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.context,
    this.contextId,
    this.status = 'active',
  });

  factory GiftGoal.fromJson(Map<String, dynamic> json) {
    return GiftGoal(
      id: (pick(json, ['id', 'goalId']) ?? '').toString(),
      title: (pick(json, ['title', 'name', 'label']) ?? 'Hedef').toString(),
      targetAmount:
          asInt(pick(json, ['targetAmount', 'target', 'goalAmount', 'amount'])),
      currentAmount: asInt(
          pick(json, ['currentAmount', 'current', 'progress', 'raised', 'total'])),
      context: pick(json, ['context'])?.toString(),
      contextId: pick(json, ['contextId'])?.toString(),
      status: (pick(json, ['status']) ?? 'active').toString(),
    );
  }

  final String id;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final String? context;
  final String? contextId;
  final String status; // active | completed

  /// 0..1 arası ilerleme oranı.
  double get progress {
    if (targetAmount <= 0) return 0;
    final r = currentAmount / targetAmount;
    return r.clamp(0.0, 1.0);
  }

  bool get isCompleted =>
      status.toLowerCase() == 'completed' || currentAmount >= targetAmount;

  bool get isActive => !isCompleted && status.toLowerCase() != 'ended';

  int get remaining {
    final r = targetAmount - currentAmount;
    return r < 0 ? 0 : r;
  }
}
