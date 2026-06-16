import 'package:equatable/equatable.dart';

class PfDailyQuest extends Equatable {
  const PfDailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardCredits,
    required this.isCompleted,
    this.progress = 0,
    this.target = 1,
  });

  final String id;
  final String title;
  final String description;
  final int rewardCredits;
  final bool isCompleted;
  final int progress;
  final int target;

  double get progressRatio => target > 0 ? (progress / target).clamp(0, 1) : 0;

  @override
  List<Object?> get props => [id, title, description, rewardCredits, isCompleted, progress, target];
}

class PfBadge extends Equatable {
  const PfBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isUnlocked;

  @override
  List<Object?> get props => [id, name, description, icon, isUnlocked];
}
