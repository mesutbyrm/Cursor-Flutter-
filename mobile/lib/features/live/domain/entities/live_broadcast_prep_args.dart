import 'package:flutter/material.dart';

/// Yayın türü seçiminden hazırlık sayfasına aktarılan veri.
class LiveBroadcastPrepArgs {
  const LiveBroadcastPrepArgs({
    required this.category,
    this.subtitle,
    this.icon = Icons.live_tv_rounded,
    this.isFortune = false,
    this.fortuneTypeSlug,
  });

  final String category;
  final String? subtitle;
  final IconData icon;
  final bool isFortune;
  final String? fortuneTypeSlug;
}
