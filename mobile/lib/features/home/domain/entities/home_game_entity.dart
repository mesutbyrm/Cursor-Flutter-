import 'package:equatable/equatable.dart';

class HomeGameEntity extends Equatable {
  const HomeGameEntity({
    required this.id,
    required this.title,
    this.icon,
    this.route,
    this.accentColorArgb,
  });

  final String id;
  final String title;
  final String? icon;
  final String? route;
  final int? accentColorArgb;

  @override
  List<Object?> get props => [id, title, icon, route, accentColorArgb];
}

class DailyRewardEntity extends Equatable {
  const DailyRewardEntity({
    required this.id,
    required this.title,
    this.description,
    this.claimed = false,
    this.rewardJeton = 0,
    this.route,
  });

  final String id;
  final String title;
  final String? description;
  final bool claimed;
  final int rewardJeton;
  final String? route;

  @override
  List<Object?> get props =>
      [id, title, description, claimed, rewardJeton, route];
}
