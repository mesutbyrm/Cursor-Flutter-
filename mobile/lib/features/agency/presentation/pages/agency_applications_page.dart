import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/agency_entity.dart';
import '../providers/agency_applications_provider.dart';
import '../providers/agency_providers.dart';

/// Ajans yöneticisi — bekleyen üye / çıkış talepleri.
class AgencyApplicationsPage extends ConsumerWidget {
  const AgencyApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(agencyMemberApplicationsProvider);

    return PlatformSocialScaffold(
      title: 'Üye talepleri',
      subtitle: 'Bekleyen çıkış ve üyelik istekleri',
      actions: [
        IconButton(
          onPressed: () => ref.invalidate(agencyMemberApplicationsProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: RefreshIndicator(
        color: PlatformSocialPalette.accent,
        onRefresh: () async {
          ref.invalidate(agencyMemberApplicationsProvider);
          await ref.read(agencyMemberApplicationsProvider.future);
        },
        child: apps.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              PlatformSocialEmptyState(
                icon: Icons.wifi_off_rounded,
                message: ApiException.userMessage(e),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  PlatformSocialEmptyState(
                    icon: Icons.inbox_outlined,
                    message: 'Bekleyen talep yok — her şey güncel.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ApplicationTile(
                item: items[i],
                onReviewed: () =>
                    ref.invalidate(agencyMemberApplicationsProvider),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ApplicationTile extends ConsumerWidget {
  const _ApplicationTile({
    required this.item,
    required this.onReviewed,
  });

  final AgencyMemberApplicationEntity item;
  final VoidCallback onReviewed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeLabel = item.type == 'leave_request'
        ? 'Ayrılma talebi'
        : 'Üyelik talebi';
    final pending = item.status == 'pending';
    return PlatformSocialGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(url: item.avatarUrl, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (item.username != null)
                      Text(
                        '@${item.username}',
                        style: const TextStyle(
                          color: PlatformSocialPalette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        PlatformSocialStatusPill(
                          label: typeLabel,
                          icon: Icons.description_outlined,
                          tone: PlatformSocialPillTone.accent,
                        ),
                        PlatformSocialStatusPill(
                          label: item.status,
                          tone: pending
                              ? PlatformSocialPillTone.gold
                              : PlatformSocialPillTone.neutral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.reason != null && item.reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              item.reason!.trim(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          if (pending && item.type == 'leave_request') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _review(ref, context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PlatformSocialPalette.danger,
                      side: const BorderSide(color: PlatformSocialPalette.danger),
                    ),
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _review(ref, context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: PlatformSocialPalette.success,
                    ),
                    child: const Text('Onayla'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _review(
    WidgetRef ref,
    BuildContext context,
    bool approve,
  ) async {
    final ok = await ref.read(agencyRemoteProvider).reviewMemberApplication(
          id: item.id,
          approve: approve,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (approve ? 'Talep onaylandı' : 'Talep reddedildi')
              : 'İşlem başarısız',
        ),
      ),
    );
    if (ok) onReviewed();
  }
}
