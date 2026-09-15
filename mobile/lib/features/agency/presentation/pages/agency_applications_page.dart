import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/agency_entity.dart';
import '../providers/agency_applications_provider.dart';
import '../providers/agency_providers.dart';

/// Ajans yöneticisi — bekleyen üye / çıkış talepleri.
class AgencyApplicationsPage extends ConsumerWidget {
  const AgencyApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(agencyMemberApplicationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1020),
      appBar: AppBar(
        title: const Text('Üye talepleri'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(agencyMemberApplicationsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(agencyMemberApplicationsProvider);
          await ref.read(agencyMemberApplicationsProvider.future);
        },
        child: apps.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  ApiException.userMessage(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.onSurfaceMuted),
                ),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Bekleyen talep yok.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.onSurfaceMuted),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(url: item.avatarUrl, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (item.username != null)
                  Text(
                    '@${item.username}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                const SizedBox(height: 4),
                Text(
                  '$typeLabel · ${item.status}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (item.reason != null && item.reason!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      item.reason!.trim(),
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                if (item.status == 'pending' && item.type == 'leave_request')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _review(ref, context, false),
                            child: const Text('Reddet'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _review(ref, context, true),
                            child: const Text('Onayla'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
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
