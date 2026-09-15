import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/util/json_util.dart';
import '../../../admin/domain/admin_user_util.dart';
import '../../../admin/presentation/widgets/admin_user_hub_launcher.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../providers/social_discovery_providers.dart';

/// Sosyal takım detayı — üye listesi + staff uzun basış → kullanıcı hub.
class SocialTeamDetailPage extends ConsumerWidget {
  const SocialTeamDetailPage({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(socialTeamDetailProvider(teamId));

    return PlatformSocialScaffold(
      title: 'Takım',
      subtitle: teamId,
      body: PlatformSocialBackground(
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(ApiException.userMessage(e)),
              ),
            ),
            data: (map) => _TeamBody(map: map, teamId: teamId),
          ),
        ),
      ),
    );
  }
}

class _TeamBody extends ConsumerWidget {
  const _TeamBody({required this.map, required this.teamId});

  final Map<String, dynamic> map;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nestedTeam = asJsonMap(map['team']);
    final team = nestedTeam.isNotEmpty ? nestedTeam : map;
    final name = (pick(team, ['name', 'title']) ?? 'Takım').toString();
    final description = pick(team, ['description', 'bio'])?.toString();
    final membersRaw = pick(team, ['members', 'users', 'items']) ??
        pick(map, ['members', 'users', 'items']);
    final members = asJsonList(membersRaw);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(socialTeamDetailProvider(teamId));
        await ref.read(socialTeamDetailProvider(teamId).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          PlatformSocialGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: PlatformSocialPalette.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          PlatformSocialSectionTitle('Üyeler (${members.length})'),
          if (members.isEmpty)
            const Text(
              'Üye listesi boş veya sunucu henüz döndürmüyor.',
              style: TextStyle(color: PlatformSocialPalette.textMuted),
            )
          else
            for (final m in members)
              _MemberRow(member: asJsonMap(m)),
        ],
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.member});

  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = resolveAdminUserId(member);
    final display = (pick(member, ['displayName', 'username', 'name']) ??
            pick(asJsonMap(member['user']), ['displayName', 'username']) ??
            'Üye')
        .toString();
    final role = pick(member, ['role', 'title'])?.toString();

    return AdminUserHubLauncher.wrap(
      context: context,
      ref: ref,
      userId: userId,
      child: PlatformSocialListRow(
        title: display,
        subtitle: role ?? userId,
        leading: CircleAvatar(
          backgroundColor: PlatformSocialPalette.accent.withValues(alpha: 0.25),
          child: Text(
            display.isNotEmpty ? display[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
