import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../domain/entities/home_page_button_entity.dart';

/// Ana sayfa homepage-buttons tıklama — `specialBehavior` + href.
String? resolveHomePageButtonRoute(HomePageButtonEntity button) {
  if (_isBroadcasterCta(button)) return '/live/type';

  final behavior = (button.specialBehavior ?? '').trim().toLowerCase();
  switch (behavior) {
    case 'bana-ozel':
    case 'bana_ozel':
      return '/fortune/bana-ozel';
    case 'teller':
    case 'falci':
      return '/falci-ol';
  }
  final link = button.linkUrl?.trim();
  if (link == null || link.isEmpty) return null;
  if (link.contains('bana-ozel')) return '/fortune/bana-ozel';
  return link;
}

bool _isBroadcasterCta(HomePageButtonEntity button) {
  final behavior = (button.specialBehavior ?? '').trim().toLowerCase();
  final label = button.label.toLowerCase();
  final link = (button.linkUrl ?? '').toLowerCase();
  if (behavior == 'broadcaster' ||
      behavior == 'yayinci' ||
      behavior == 'go-live' ||
      behavior == 'golive' ||
      behavior.contains('yayin')) {
    return true;
  }
  if (link.contains('yayinci-ol') || link.contains('yayinci-panel')) {
    return true;
  }
  return label.contains('yayıncı') || label.contains('yayinci');
}

void navigateHomePageButton(BuildContext context, HomePageButtonEntity button) {
  final resolved = resolveHomePageButtonRoute(button);
  if (resolved == null) return;
  if (resolved == '/fortune/bana-ozel' ||
      resolved == '/falci-ol' ||
      resolved == '/live/type') {
    context.push(resolved);
    return;
  }
  openNativeSitePath(context, resolved);
}
