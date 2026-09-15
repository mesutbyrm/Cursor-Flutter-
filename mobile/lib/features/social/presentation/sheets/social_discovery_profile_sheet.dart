import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
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
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: context.colors.onSurfaceMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: UserAvatar(url: user.avatarUrl, radius: 48)),
              const SizedBox(height: 12),
              Text(
                user.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (user.username != null && user.username!.isNotEmpty)
                Text(
                  '@${user.username}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.onSurfaceMuted),
                ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (online)
                    Chip(
                      label: const Text('Çevrimiçi'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (age is num)
                    Chip(
                      label: Text('${age.round()} yaş'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (user.distanceLabel != null)
                    Chip(
                      label: Text(user.distanceLabel!),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (bio != null && bio.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(bio.trim()),
              ],
              if (interests.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'İlgi alanları',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: interests
                      .take(8)
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/user/${Uri.encodeComponent(user.id)}');
                },
                icon: const Icon(Icons.person_outline),
                label: const Text('Tam profile git'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onSkip != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onSkip!();
                        },
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
                child: const Text('Şikayet et'),
              ),
            ],
          ),
        );
      },
    );
  }
}
