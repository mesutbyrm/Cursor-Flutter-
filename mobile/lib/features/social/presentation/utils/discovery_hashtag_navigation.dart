import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/social_discovery_providers.dart';

/// Hashtag / ilgi alanı seçimini keşif filtresine uygular ve Tanış ana ekrana döner.
void applyDiscoveryInterestFilter(
  BuildContext context,
  WidgetRef ref, {
  required String interest,
  String? snackMessage,
}) {
  final clean = interest.replaceFirst('#', '').trim();
  if (clean.isEmpty) return;
  ref.read(discoveryFilterProvider.notifier).state =
      ref.read(discoveryFilterProvider).copyWith(interestQuery: clean);
  ref.invalidate(socialDiscoveryFeedProvider);
  if (context.mounted) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/social/tanis-kaynas');
    }
    if (snackMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackMessage)),
      );
    }
  }
}
