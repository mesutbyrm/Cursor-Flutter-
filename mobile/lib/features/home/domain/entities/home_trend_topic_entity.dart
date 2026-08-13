import 'package:equatable/equatable.dart';

/// `GET /api/trends` — ana sayfa trend etiketleri.
class HomeTrendTopicEntity extends Equatable {
  const HomeTrendTopicEntity({
    required this.tag,
    this.viewsLabel,
    this.route,
  });

  final String tag;
  final String? viewsLabel;
  final String? route;

  @override
  List<Object?> get props => [tag, viewsLabel, route];
}
