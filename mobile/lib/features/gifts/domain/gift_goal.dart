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
    this.percent,
    this.endsAt,
    this.durationMinutes,
    this.createdAt,
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
      percent: _parsePercent(pick(json, ['percent'])),
      endsAt: _parseDate(pick(json, ['endsAt', 'endAt', 'expiresAt', 'deadline'])),
      durationMinutes: asInt(pick(json, ['durationMinutes', 'durationMin'])),
      createdAt: _parseDate(
        pick(json, ['createdAt', 'startedAt', 'created_at', 'startAt']),
      ),
    ).withResolvedDeadline();
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  static double? _parsePercent(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  final String id;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final String? context;
  final String? contextId;
  final String status; // active | completed
  final double? percent;
  final DateTime? endsAt;
  final int? durationMinutes;
  final DateTime? createdAt;

  /// Sunucu `endsAt` göndermezse `createdAt` + `durationMinutes` ile hesapla.
  GiftGoal withResolvedDeadline({DateTime? now, int? fallbackDurationMinutes}) {
    if (endsAt != null) return this;
    final mins = durationMinutes ?? fallbackDurationMinutes;
    if (mins == null || mins <= 0) return this;
    final base = createdAt ?? now ?? DateTime.now().toUtc();
    return GiftGoal(
      id: id,
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      context: context,
      contextId: contextId,
      status: status,
      percent: percent,
      endsAt: base.add(Duration(minutes: mins)),
      durationMinutes: mins,
      createdAt: createdAt ?? base,
    );
  }

  /// 0..1 arası ilerleme oranı.
  double get progress {
    if (percent != null && percent! >= 0) {
      return (percent! / 100).clamp(0.0, 1.0);
    }
    if (targetAmount <= 0) return 0;
    final r = currentAmount / targetAmount;
    return r.clamp(0.0, 1.0);
  }

  bool get isCompleted =>
      status.toLowerCase() == 'completed' || currentAmount >= targetAmount;

  bool get isActive => !isCompleted && status.toLowerCase() != 'ended';

  Duration? get remainingTime {
    if (endsAt == null) return null;
    final left = endsAt!.difference(DateTime.now());
    if (left.isNegative) return Duration.zero;
    return left;
  }

  int get remaining {
    final r = targetAmount - currentAmount;
    return r < 0 ? 0 : r;
  }
}
