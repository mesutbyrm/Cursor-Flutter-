import 'package:equatable/equatable.dart';

class HomeBannerQuickAction extends Equatable {
  const HomeBannerQuickAction({
    required this.id,
    required this.label,
    this.route,
  });

  final String id;
  final String label;
  final String? route;

  @override
  List<Object?> get props => [id, label, route];
}

class HomeBannerEntity extends Equatable {
  const HomeBannerEntity({
    required this.id,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.ctaRoute,
    this.imageUrl,
    this.gradient = const [0xFF2A1548, 0xFF7B4DFF],
    this.quickActions = const [],
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final String? ctaRoute;
  final String? imageUrl;
  final List<int> gradient;
  final List<HomeBannerQuickAction> quickActions;

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        ctaLabel,
        ctaRoute,
        imageUrl,
        gradient,
        quickActions,
      ];
}
