import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'membership_capability_providers.dart';

/// Capability yoksa üyelik yükseltme CTA gösterir.
class MembershipCapabilityLockedBody extends ConsumerWidget {
  const MembershipCapabilityLockedBody({
    super.key,
    required this.capabilityKey,
    required this.title,
    required this.message,
    this.upgradeRoute = '/premium-membership',
  });

  final String capabilityKey;
  final String title;
  final String message;
  final String upgradeRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed =
        ref.watch(membershipCapabilitiesSyncProvider).allows(capabilityKey);
    if (allowed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.push(upgradeRoute),
              child: const Text('Üyeliği yükselt'),
            ),
          ],
        ),
      ),
    );
  }
}
