import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../providers/agency_providers.dart';

class AgencyInvite {
  const AgencyInvite({
    required this.id,
    required this.agencyName,
    this.agencyLogo,
    this.invitedBy,
  });

  final String id;
  final String agencyName;
  final String? agencyLogo;
  final String? invitedBy;

  factory AgencyInvite.fromJson(Map<String, dynamic> j) {
    final agency = j['agency'] is Map ? Map<String, dynamic>.from(j['agency'] as Map) : const <String, dynamic>{};
    final by = j['invitedBy'] is Map ? Map<String, dynamic>.from(j['invitedBy'] as Map) : const <String, dynamic>{};
    return AgencyInvite(
      id: '${j['id'] ?? ''}',
      agencyName: '${agency['name'] ?? 'Ajans'}',
      agencyLogo: agency['logoUrl']?.toString(),
      invitedBy: (by['name'] ?? by['username'])?.toString(),
    );
  }
}

/// `GET /api/agency/invites` — kullanıcının bekleyen ajans davetleri.
final agencyInvitesProvider =
    FutureProvider.autoDispose<List<AgencyInvite>>((ref) async {
  final res = await ref.watch(dioProvider).safeGet<dynamic>(
        ApiEndpoints.agencyInvites,
        forceRefresh: true,
      );
  final body = res.data;
  final list = body is Map ? body['invites'] : null;
  if (list is! List) return const [];
  return list
      .whereType<Map>()
      .map((e) => AgencyInvite.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});

/// Üye onayı olmadan kimse ajansa eklenmez: davet kabul / red ekranı.
class AgencyInvitesPage extends ConsumerWidget {
  const AgencyInvitesPage({super.key});

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    AgencyInvite invite,
    bool accept,
  ) async {
    try {
      await ref.read(dioProvider).safePost<dynamic>(
        ApiEndpoints.agencyInvites,
        data: {'inviteId': invite.id, 'action': accept ? 'accept' : 'reject'},
      );
      ref.invalidate(agencyInvitesProvider);
      if (accept) ref.read(approvedAgencyProvider.notifier).refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Ajansa katıldınız.' : 'Davet reddedildi.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(agencyInvitesProvider);
    return PlatformSocialScaffold(
      title: 'Ajans davetleri',
      subtitle: 'Onayınız olmadan hiçbir ajansa eklenmezsiniz',
      body: RefreshIndicator(
        color: PlatformSocialPalette.accent,
        onRefresh: () async {
          ref.invalidate(agencyInvitesProvider);
          await ref.read(agencyInvitesProvider.future);
        },
        child: invites.when(
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
                    icon: Icons.mail_outline_rounded,
                    message: 'Bekleyen ajans davetiniz yok.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final inv = items[i];
                return PlatformSocialGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          UserAvatar(url: inv.agencyLogo, radius: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inv.agencyName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                if (inv.invitedBy != null)
                                  Text('Davet eden: ${inv.invitedBy}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _respond(context, ref, inv, false),
                              child: const Text('Reddet'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _respond(context, ref, inv, true),
                              child: const Text('Kabul et'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
