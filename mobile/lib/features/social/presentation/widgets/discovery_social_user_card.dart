import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/cds.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../admin/presentation/widgets/admin_user_hub_launcher.dart';
import '../../domain/entities/social_discovery_user.dart';

/// Tanış & sosyal keşif — ortak CDS kart (Like / Geç).
class DiscoverySocialUserCard extends ConsumerWidget {
  const DiscoverySocialUserCard({
    super.key,
    required this.user,
    required this.onOpenProfile,
    required this.onLike,
    required this.onSkip,
    this.onReport,
  });

  final SocialDiscoveryUser user;
  final VoidCallback onOpenProfile;
  final VoidCallback onLike;
  final VoidCallback onSkip;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = user;
    final rawUser = u.raw['user'] is Map
        ? asJsonMap(u.raw['user'])
        : asJsonMap(u.raw);
    final age = pick(rawUser, ['age', 'userAge']);
    final online = pick(rawUser, ['isOnline', 'online']) == true;
    final interestsRaw = pick(rawUser, ['interests', 'tags', 'hobbies']);
    String? interestsLine;
    if (interestsRaw is List) {
      interestsLine = interestsRaw.take(3).map((e) => e.toString()).join(' · ');
    } else if (interestsRaw != null) {
      interestsLine = interestsRaw.toString();
    }

    final hubChild = Semantics(
      container: true,
      label: '${u.displayName} keşif kartı',
      child: CdsCard(
        variant: CdsCardVariant.interactive,
        onTap: onOpenProfile,
        padding: const EdgeInsets.all(CdsSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(url: u.avatarUrl, radius: 28),
            const SizedBox(width: CdsSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CdsTypography.title(context).copyWith(fontSize: 16),
                  ),
                  if (u.username != null && u.username!.isNotEmpty)
                    Text(
                      '@${u.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CdsTypography.caption(context),
                    ),
                  if (age is num)
                    Text(
                      '${age.round()} yaş',
                      style: CdsTypography.caption(context),
                    ),
                  if (u.distanceLabel != null)
                    Text(
                      u.distanceLabel!,
                      style: CdsTypography.caption(context).copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                  if (online)
                    Text(
                      'Çevrimiçi',
                      style: CdsTypography.caption(context).copyWith(
                        color: AppThemeColors.onlineGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (interestsLine != null && interestsLine.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        interestsLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CdsTypography.caption(context),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Semantics(
                  button: true,
                  label: 'Beğen',
                  child: IconButton(
                    tooltip: 'Beğen',
                    onPressed: onLike,
                    icon: const Icon(Icons.favorite_border_rounded),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Geç',
                  child: IconButton(
                    tooltip: 'Geç',
                    onPressed: onSkip,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ),
                if (onReport != null)
                  Semantics(
                    button: true,
                    label: 'Şikayet',
                    child: IconButton(
                      tooltip: 'Şikayet',
                      onPressed: onReport,
                      icon: const Icon(Icons.flag_outlined),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (u.id.isEmpty) return hubChild;
    return AdminUserHubLauncher.wrap(
      context: context,
      ref: ref,
      userId: u.id,
      onTap: onOpenProfile,
      child: hubChild,
    );
  }
}
