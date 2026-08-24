import 'package:equatable/equatable.dart';

/// `GET /api/blog/recent` — ana sayfa blog önizlemesi.
class HomeBlogPostEntity extends Equatable {
  const HomeBlogPostEntity({
    required this.id,
    required this.title,
    required this.route,
    this.excerpt,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String route;
  final String? excerpt;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, title, route, excerpt, imageUrl];
}
