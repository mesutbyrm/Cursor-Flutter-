import 'package:equatable/equatable.dart';

/// `GET /api/homepage-buttons` — ana sayfa hızlı erişim butonları.
class HomePageButtonEntity extends Equatable {
  const HomePageButtonEntity({
    required this.id,
    required this.label,
    this.iconUrl,
    this.linkUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String label;
  final String? iconUrl;
  final String? linkUrl;
  final int sortOrder;
  final bool isActive;

  @override
  List<Object?> get props => [id, label, iconUrl, linkUrl, sortOrder, isActive];
}
