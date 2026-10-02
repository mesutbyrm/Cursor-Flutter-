import 'package:canlifal_social/core/design_system/cds_bottom_sheet.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../search/presentation/providers/search_providers.dart';
import '../../providers/live_stream_viewers_provider.dart';

/// Yayıncı — "Misafir Davet Et" bottom sheet'i.
///
/// Arama boşken yayındaki izleyiciler listelenir; 2+ karakterle tüm kullanıcılar
/// aranır. [onInvite] başarılıysa `true` döner; satır "Davet gönderildi" olur.
Future<void> showLiveGuestInviteSheet(
  BuildContext context,
  WidgetRef ref, {
  required String streamId,
  required String hostUserId,
  required Future<bool> Function(String userId, String displayName) onInvite,
}) async {
  try {
    await CdsBottomSheet.show<void>(
      context: context,
      child: _GuestInviteSheet(
        streamId: streamId,
        hostUserId: hostUserId,
        onInvite: onInvite,
      ),
    );
  } finally {
    // Arama durumu global; sheet kapanınca sıfırla.
    ref.read(userSearchProvider.notifier).setQuery('');
  }
}

class _Candidate {
  const _Candidate({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;
}

class _GuestInviteSheet extends ConsumerStatefulWidget {
  const _GuestInviteSheet({
    required this.streamId,
    required this.hostUserId,
    required this.onInvite,
  });

  final String streamId;
  final String hostUserId;
  final Future<bool> Function(String userId, String displayName) onInvite;

  @override
  ConsumerState<_GuestInviteSheet> createState() => _GuestInviteSheetState();
}

class _GuestInviteSheetState extends ConsumerState<_GuestInviteSheet> {
  final _query = TextEditingController();
  final _sent = <String>{};
  final _sending = <String>{};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _invite(_Candidate c) async {
    if (_sending.contains(c.id) || _sent.contains(c.id)) return;
    setState(() => _sending.add(c.id));
    var ok = false;
    try {
      ok = await widget.onInvite(c.id, c.name);
    } finally {
      if (mounted) {
        setState(() {
          _sending.remove(c.id);
          if (ok) _sent.add(c.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim();
    final searching = q.length >= 2;
    final async = searching
        ? ref.watch(userSearchProvider).whenData(
            (list) => [
              for (final u in list)
                _Candidate(
                  id: u.id,
                  name: u.name.isNotEmpty ? u.name : u.username,
                  username: u.username,
                  avatarUrl: u.image,
                ),
            ],
          )
        : ref.watch(liveStreamViewersProvider(widget.streamId)).whenData(
            (list) => [
              for (final v in list)
                if (v.id.isNotEmpty && !v.isBroadcaster)
                  _Candidate(
                    id: v.id,
                    name: v.displayName,
                    username: v.username,
                    avatarUrl: v.avatarUrl,
                  ),
            ],
          );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.62,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Misafir Davet Et',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _query,
              onChanged: (v) {
                ref.read(userSearchProvider.notifier).setQuery(v);
                setState(() {});
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Kullanıcı ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text('Liste yüklenemedi')),
              data: (list) {
                final items = [
                  for (final c in list)
                    if (c.id != widget.hostUserId) c,
                ];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      searching
                          ? 'Kullanıcı bulunamadı'
                          : 'Henüz izleyici yok — kullanıcı arayın',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final c = items[i];
                    return _Row(
                      candidate: c,
                      sending: _sending.contains(c.id),
                      sent: _sent.contains(c.id),
                      onInvite: () => _invite(c),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.candidate,
    required this.sending,
    required this.sent,
    required this.onInvite,
  });

  final _Candidate candidate;
  final bool sending;
  final bool sent;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(url: candidate.avatarUrl, radius: 22),
      title: Text(
        candidate.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: candidate.username != null && candidate.username!.isNotEmpty
          ? Text('@${candidate.username}', maxLines: 1)
          : null,
      trailing: SizedBox(
        width: 104,
        height: 36,
        child: FilledButton(
          onPressed: sent || sending ? null : onInvite,
          style: FilledButton.styleFrom(
            backgroundColor: AppThemeColors.accentPink,
            disabledBackgroundColor: Colors.white12,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  sent ? 'Gönderildi' : 'Davet Et',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: sent ? Colors.white54 : Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
