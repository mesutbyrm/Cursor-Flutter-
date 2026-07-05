import '../../../core/util/json_util.dart';

/// Günlük görev — `/api/gifts/missions` (tanım) + `/api/gifts/missions/me`
/// (bugünkü ilerleme). İki yanıt tek modelde birleştirilir.
class GiftMission {
  const GiftMission({
    required this.id,
    required this.title,
    this.description,
    this.target = 0,
    this.progress = 0,
    this.reward = 0,
    this.rewardLabel,
    this.completed = false,
    this.claimed = false,
  });

  factory GiftMission.fromJson(Map<String, dynamic> json) {
    final target = asInt(pick(json, ['target', 'goal', 'targetAmount', 'required']));
    final progress = asInt(pick(json, ['progress', 'current', 'done']));
    final completedFlag = pick(json, ['completed', 'isCompleted']);
    return GiftMission(
      id: (pick(json, ['id', 'missionId', 'code']) ?? '').toString(),
      title: (pick(json, ['title', 'name', 'label']) ?? 'Görev').toString(),
      description: pick(json, ['description', 'desc', 'subtitle'])?.toString(),
      target: target,
      progress: progress,
      reward: asInt(pick(json, ['reward', 'rewardAmount', 'prize'])),
      rewardLabel: pick(json, ['rewardLabel', 'rewardText'])?.toString(),
      completed: completedFlag is bool
          ? completedFlag
          : (target > 0 && progress >= target),
      claimed: pick(json, ['claimed', 'isClaimed']) == true,
    );
  }

  final String id;
  final String title;
  final String? description;
  final int target;
  final int progress;
  final int reward;
  final String? rewardLabel;
  final bool completed;
  final bool claimed;

  double get progressRatio {
    if (target <= 0) return completed ? 1 : 0;
    return (progress / target).clamp(0.0, 1.0);
  }

  bool get canClaim => completed && !claimed;
}
