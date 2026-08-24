import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../domain/entities/home_page_button_entity.dart';

/// Ana sayfa homepage-buttons tıklama — `specialBehavior` + href.
String? resolveHomePageButtonRoute(HomePageButtonEntity button) {
  final behavior = (button.specialBehavior ?? '').trim().toLowerCase();
  switch (behavior) {
    case 'bana-ozel':
    case 'bana_ozel':
      return '/fortune/bana-ozel';
    case 'teller':
      return '/falci-ol';
  }
  final link = button.linkUrl?.trim();
  if (link == null || link.isEmpty) return null;
  if (link.contains('bana-ozel')) return '/fortune/bana-ozel';
  return link;
}

void navigateHomePageButton(BuildContext context, HomePageButtonEntity button) {
  final resolved = resolveHomePageButtonRoute(button);
  if (resolved == null) return;
  if (resolved == '/fortune/bana-ozel' || resolved == '/falci-ol') {
    context.push(resolved);
    return;
  }
  openNativeSitePath(context, resolved);
}
