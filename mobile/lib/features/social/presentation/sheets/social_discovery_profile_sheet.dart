import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/social_discovery_user.dart';

/// Tanış keşif — zengin profil önizleme (tam profile gitmeden).
Future<void> showSocialDiscoveryProfileSheet(
  BuildContext context, {
  required SocialDiscoveryUser user,
  VoidCallback? onLike,
  VoidCallback? onSkip,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SocialDiscoveryProfileSheet(
      user: user,
      onLike: onLike,
      onSkip: onSkip,
    ),
  );
}

class _SocialDiscoveryProfileSheet extends StatelessWidget {
  const _SocialDiscoveryProfileSheet({
    required this.user,
    this.onLike,
    this.onSkip,
  });

  final SocialDiscoveryUser user;
  final VoidCallback? onLike;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final rawUser = user.raw['user'] is Map
        ? asJsonMap(user.raw['user'])
        : asJsonMap(user.raw);
    final age = pick(rawUser, ['age', 'userAge']);
    final bio = pick(rawUser, ['bio', 'about'])?.toString();
    final online = pick(rawUser, ['isOnline', 'online']) == true;
    final interestsRaw = pick(rawUser, ['interests', 'tags', 'hobbies']);
    final interests = interestsRaw is List
        ? interestsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: PlatformSocialPalette.backgroundGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PlatformSocialGlassCard(
                gradient: PlatformSocialPalette.heroGradient,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    UserAvatar(url: user.avatarUrl, radius: 52),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if (user.username != null && user.username!.isNotEmpty)
                      Text(
                        '@${user.username}',
                        style: const TextStyle(color: PlatformSocialPalette.textMuted),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (online)
                          const PlatformSocialStatusPill(
                            label: 'Çevrimiçi',
                            icon: Icons.circle,
                            tone: PlatformSocialPillTone.success,
                          ),
                        if (age is num)
                          PlatformSocialStatusPill(
                            label: '${age.round()} yaş',
                            icon: Icons.cake_outlined,
                          ),
                        if (user.distanceLabel != null)
                          PlatformSocialStatusPill(
                            label: user.distanceLabel!,
                            icon: Icons.place_outlined,
                            tone: PlatformSocialPillTone.accent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (bio != null && bio.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const PlatformSocialSectionTitle('Hakkında'),
                PlatformSocialGlassCard(
                  child: Text(bio.trim(), style: const TextStyle(height: 1.45)),
                ),
              ],
              if (interests.isNotEmpty) ...[
                const SizedBox(height: 16),
                const PlatformSocialSectionTitle('İlgi alanları'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests.take(10).map((t) {
                    return PlatformSocialStatusPill(label: t, tone: PlatformSocialPillTone.accent);
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              PlatformSocialPrimaryButton(
                label: 'Tam profile git',
                icon: Icons.person_outline_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/user/${Uri.encodeComponent(user.id)}');
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onSkip != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onSkip!();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Geç'),
                      ),
                    ),
                  if (onSkip != null && onLike != null) const SizedBox(width: 10),
                  if (onLike != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onLike!();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: PlatformSocialPalette.danger,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Beğen'),
                      ),
                    ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openReportFlow(
                    context,
                    ReportTarget(
                      type: ReportTargetType.user,
                      targetId: user.id,
                      displayTitle: user.displayName,
                    ),
                  );
                },
                child: const Text('Şikayet et', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        );
      },
    );
  }
}
