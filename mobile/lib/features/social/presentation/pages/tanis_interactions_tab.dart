import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../admin/presentation/widgets/admin_user_hub_launcher.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../providers/social_discovery_providers.dart';
import '../sheets/social_discovery_profile_sheet.dart';
import '../utils/social_discovery_time_label.dart';

class TanisInteractionsTab extends ConsumerStatefulWidget {
  const TanisInteractionsTab({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  ConsumerState<TanisInteractionsTab> createState() =>
      _TanisInteractionsTabState();
}

class _TanisInteractionsTabState extends ConsumerState<TanisInteractionsTab> {
  String? _typeFilter;

  SocialDiscoveryUser? _interactionTargetUser(Map<String, dynamic> row) {
    return SocialDiscoveryUser.fromActionRow(row);
  }

  String _actionSuccessLabel(String type) {
    switch (type) {
      case 'like':
        return 'Beğeni';
      case 'favorite':
        return 'Süper beğeni (favori)';
      case 'friend_request':
        return 'Arkadaşlık isteği';
      case 'block':
        return 'Engel';
      case 'skip':
        return 'Geçildi';
      default:
        return type;
    }
  }

  List<Map<String, dynamic>> _filterRows(List<Map<String, dynamic>> rows) {
    if (_typeFilter == null || _typeFilter!.isEmpty) return rows;
    return rows.where((row) {
      final type = (pick(row, ['type', 'action']) ?? '').toString();
      return type == _typeFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.watch(socialDiscoveryActionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(socialDiscoveryActionsProvider);
        await widget.onRefresh();
      },
      child: actions.when(
        loading: () => ListView(
          children: const [
            SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (e, _) => ListView(
          children: [
            DiscoverEmptyState(
              icon: Icons.history_rounded,
              message: ApiException.userMessage(e),
              actionLabel: 'Yenile',
              action: () => ref.invalidate(socialDiscoveryActionsProvider),
            ),
          ],
        ),
        data: (rows) {
          final filtered = _filterRows(rows);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Tümü',
                      selected: _typeFilter == null,
                      onTap: () => setState(() => _typeFilter = null),
                    ),
                    _FilterChip(
                      label: 'Beğeni',
                      selected: _typeFilter == 'like',
                      onTap: () => setState(() => _typeFilter = 'like'),
                    ),
                    _FilterChip(
                      label: 'Favori',
                      selected: _typeFilter == 'favorite',
                      onTap: () => setState(() => _typeFilter = 'favorite'),
                    ),
                    _FilterChip(
                      label: 'Arkadaşlık',
                      selected: _typeFilter == 'friend_request',
                      onTap: () =>
                          setState(() => _typeFilter = 'friend_request'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const DiscoverEmptyState(
                  icon: Icons.inbox_outlined,
                  message: 'Bu filtrede etkileşim yok.',
                )
              else
                ...filtered.map((row) {
                  final type =
                      (pick(row, ['type', 'action']) ?? '').toString();
                  final targetUser = _interactionTargetUser(row);
                  final targetId = targetUser?.id ?? '';
                  final title = targetUser?.displayName ??
                      (targetId.isNotEmpty ? targetId : null) ??
                      _actionSuccessLabel(type);
                  final when = socialDiscoveryRelativeTimeLabel(
                    targetUser?.actionAt,
                  );
                  final tile = PlatformSocialInteractionTile(
                    actionLabel: _actionSuccessLabel(type),
                    targetLabel: when != null ? '$title · $when' : title,
                    icon: platformSocialActionIcon(type),
                    onTap: targetUser == null
                        ? null
                        : () => showSocialDiscoveryProfileSheet(
                              context,
                              user: targetUser,
                            ),
                  );
                  if (targetId.isEmpty) return tile;
                  return AdminUserHubLauncher.wrap(
                    context: context,
                    ref: ref,
                    userId: targetId,
                    onTap: targetUser == null
                        ? null
                        : () => showSocialDiscoveryProfileSheet(
                              context,
                              user: targetUser,
                            ),
                    child: tile,
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
