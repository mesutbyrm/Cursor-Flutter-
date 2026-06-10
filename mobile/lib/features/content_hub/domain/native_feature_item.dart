import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum NativeFeatureHubKind {
  games,
  dreams,
  blog,
  celebrities,
  fanClub,
  adRewards,
}

class NativeFeatureItem extends Equatable {
  const NativeFeatureItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    this.imageUrl,
    this.metricLabel,
    this.badge,
  });

  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final String? imageUrl;
  final String? metricLabel;
  final String? badge;

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    route,
    icon,
    imageUrl,
    metricLabel,
    badge,
  ];
}
