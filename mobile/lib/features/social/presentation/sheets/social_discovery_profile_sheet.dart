import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../providers/social_discovery_providers.dart';

/// Tanış keşif — zengin profil önizleme (tam profile gitmeden).
Future<void> showSocialDiscoveryProfileSheet(
  BuildContext context, {
  required SocialDiscoveryUser user,
  VoidCallback? onLike,
  VoidCallback? onSkip,
  VoidCallback? onBlocked,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SocialDiscoveryProfileSheet(
      user: user,
      onLike: onLike,
      onSkip: onSkip,
      onBlocked: onBlocked,
    ),
  );
}

class _SocialDiscoveryProfileSheet extends ConsumerStatefulWidget {
  const _SocialDiscoveryProfileSheet({
    required this.user,
    this.onLike,
    this.onSkip,
    this.onBlocked,
  });

  final SocialDiscoveryUser user;
  final VoidCallback? onLike;
  final VoidCallback? onSkip;
  final VoidCallback? onBlocked;

  @override
  ConsumerState<_SocialDiscoveryProfileSheet> createState() =>
      _SocialDiscoveryProfileSheetState();
}

class _SocialDiscoveryProfileSheetState
    extends ConsumerState<_SocialDiscoveryProfileSheet> {
  var _friendBusy = false;

  Map<String, dynamic> _mergedProfile(Map<String, dynamic>? remote) {
    if (remote == null || remote.isEmpty) {
      return widget.user.raw['user'] is Map
          ? asJsonMap(widget.user.raw['user'])
          : asJsonMap(widget.user.raw);
    }
    return remote;
  }

  Future<void> _sendFriendRequest() async {
    setState(() => _friendBusy = true);
    try {
      final result = await ref.read(socialDiscoveryRemoteProvider).postAction(
            type: 'friend_request',
            targetId: widget.user.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? (result.message ?? 'Arkadaşlık isteği gönderildi')
                : (result.message ?? 'İstek gönderilemedi'),
          ),
        ),
      );
      if (result.success) {
        ref.invalidate(socialDiscoveryProfileProvider(widget.user.id));
        ref.invalidate(socialDiscoveryActionsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _friendBusy = false);
    }
  }

  Future<void> _blockUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Engelle'),
        content: Text(
          '${widget.user.displayName} engellensin mi? Keşifte bir daha görünmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final result = await ref.read(socialDiscoveryRemoteProvider).postAction(
            type: 'block',
            targetId: widget.user.id,
          );
      if (!mounted) return;
      if (result.success) {
        Navigator.of(context).pop();
        widget.onBlocked?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı engellendi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Engelleme başarısız')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync =
        ref.watch(socialDiscoveryProfileProvider(widget.user.id));

    return profileAsync.when(
      loading: () => _sheetBody(context, _mergedProfile(null), loading: true),
      error: (_, _) => _sheetBody(context, _mergedProfile(null)),
      data: (remote) => _sheetBody(context, _mergedProfile(remote)),
    );
  }

  Widget _sheetBody(
    BuildContext context,
    Map<String, dynamic> rawUser, {
    bool loading = false,
  }) {
    final age = pick(rawUser, ['age', 'userAge']);
    final bio = pick(rawUser, ['bio', 'about'])?.toString();
    final online = pick(rawUser, ['isOnline', 'online']) == true;
    final matchPercent = pick(rawUser, ['matchPercent']);
    final interestsRaw = pick(rawUser, [
      'commonHobbies',
      'interests',
      'tags',
      'hobbies',
    ]);
    final interests = interestsRaw is List
        ? interestsRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];
    final friendStatus =
        pick(rawUser, ['friendStatus', 'friendshipStatus'])?.toString();
    final isBlocked = pick(rawUser, ['isBlocked']) == true;
    final canFriendRequest = !isBlocked &&
        friendStatus != 'pending' &&
        friendStatus != 'friends' &&
        friendStatus != 'accepted';

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
                    UserAvatar(url: widget.user.avatarUrl, radius: 52),
                    const SizedBox(height: 12),
                    Text(
                      widget.user.displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.user.username != null &&
                        widget.user.username!.isNotEmpty)
                      Text(
                        '@${widget.user.username}',
                        style: const TextStyle(
                          color: PlatformSocialPalette.textMuted,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (loading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
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
                        if (widget.user.distanceLabel != null)
                          PlatformSocialStatusPill(
                            label: widget.user.distanceLabel!,
                            icon: Icons.place_outlined,
                            tone: PlatformSocialPillTone.accent,
                          ),
                        if (matchPercent is num && matchPercent > 0)
                          PlatformSocialStatusPill(
                            label: '%${matchPercent.round()} uyum',
                            icon: Icons.auto_awesome_rounded,
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
                    return PlatformSocialStatusPill(
                      label: t,
                      tone: PlatformSocialPillTone.accent,
                    );
                  }).toList(),
                ),
              ],
              if (canFriendRequest) ...[
                const SizedBox(height: 16),
                PlatformSocialPrimaryButton(
                  label: 'Arkadaşlık isteği',
                  icon: Icons.person_add_outlined,
                  loading: _friendBusy,
                  onPressed: _friendBusy ? null : _sendFriendRequest,
                ),
              ] else if (friendStatus == 'pending') ...[
                const SizedBox(height: 16),
                const PlatformSocialStatusPill(
                  label: 'Arkadaşlık isteği bekliyor',
                  icon: Icons.hourglass_top_rounded,
                ),
              ],
              const SizedBox(height: 24),
              PlatformSocialPrimaryButton(
                label: 'Tam profile git',
                icon: Icons.person_outline_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/user/${Uri.encodeComponent(widget.user.id)}');
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.onSkip != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onSkip!();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Geç'),
                      ),
                    ),
                  if (widget.onSkip != null && widget.onLike != null)
                    const SizedBox(width: 10),
                  if (widget.onLike != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onLike!();
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
                      targetId: widget.user.id,
                      displayTitle: widget.user.displayName,
                    ),
                  );
                },
                child: const Text(
                  'Şikayet et',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              if (!isBlocked)
                TextButton(
                  onPressed: _blockUser,
                  child: const Text(
                    'Engelle',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
