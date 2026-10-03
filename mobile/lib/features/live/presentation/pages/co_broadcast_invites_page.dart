import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover/discover_tab_pages.dart';
import '../../../../core/widgets/settings_kit.dart';
import '../providers/co_broadcast_provider.dart';
import '../utils/co_broadcast_invite_actions.dart';

/// `/co-broadcast-invites` — `GET /api/user/co-broadcast-invites`; kabul/ret
/// `PATCH /api/video-streams/{id}/co-broadcast`.
class CoBroadcastInvitesPage extends ConsumerStatefulWidget {
  const CoBroadcastInvitesPage({super.key});

  @override
  ConsumerState<CoBroadcastInvitesPage> createState() =>
      _CoBroadcastInvitesPageState();
}

class _CoBroadcastInvitesPageState
    extends ConsumerState<CoBroadcastInvitesPage> {
  final _busy = <String>{};
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    await ref.read(coBroadcastProvider.notifier).refresh();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _respond(String streamId, {required bool accept}) async {
    setState(() => _busy.add(streamId));
    try {
      if (accept) {
        await acceptCoBroadcastInviteAndJoin(ref, streamId);
      } else {
        await ref.read(coBroadcastProvider.notifier).rejectInvite(streamId);
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(streamId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(currentUserIdProvider) ?? '';
    final invites = ref
        .watch(coBroadcastProvider)
        .invites
        .where((i) => isPendingCoBroadcastInvite(i, myId))
        .where((i) => coBroadcastInviteStreamId(i).isNotEmpty)
        .toList();
    final c = context.colors;
    return DiscoverSubPage(
      title: 'Ortak yayın davetleri',
      subtitle: 'Canlı yayına misafir olarak katıl',
      onRefresh: _refresh,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (invites.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.podcasts_rounded, size: 48, color: c.onSurfaceMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Bekleyen davetin yok. Yayıncılar seni misafir olarak '
                      'davet ettiğinde burada görünür.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              for (final invite in invites) _inviteCard(invite),
          ],
        ),
      ),
    );
  }

  Widget _inviteCard(Map<String, dynamic> invite) {
    final streamId = coBroadcastInviteStreamId(invite);
    final broadcaster = invite['broadcaster'];
    final image = broadcaster is Map ? broadcaster['image']?.toString() : null;
    final title = invite['streamTitle']?.toString() ?? '';
    final busy = _busy.contains(streamId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SettingsPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: image != null && image.startsWith('http')
                      ? CanlifalNetworkImage(
                          url: image,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : const CircleAvatar(child: Icon(Icons.person_rounded)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coBroadcastInviteHostName(invite),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      if (title.isNotEmpty)
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _respond(streamId, accept: false),
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : () => _respond(streamId, accept: true),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kabul et ve katıl'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
