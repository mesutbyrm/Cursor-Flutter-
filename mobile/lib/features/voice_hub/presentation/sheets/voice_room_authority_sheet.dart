import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_moderation_target_color.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_glass.dart';
import '../widgets/premium/voice_neon_avatar.dart';
import 'voice_room_moderation_sheet.dart';

/// Faz 4 — Yetki Ver: kullanıcı seç → rol / moderasyon aksiyonları.
Future<void> showVoiceRoomAuthoritySheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required bool isOwner,
}) {
  final canOpen = perms.isSiteAdmin ||
      perms.isRoomOwner ||
      perms.canModerate ||
      perms.canManageRoom ||
      perms.canMuteUsers ||
      perms.canKickUsers ||
      perms.canBanUsers;
  if (!canOpen) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yetki yönetimi için yetkiniz yok')),
    );
    return Future.value();
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(ctx),
      child: _VoiceRoomAuthoritySheet(
        room: room,
        live: live,
        perms: perms,
        isOwner: isOwner,
      ),
    ),
  );
}

class _VoiceRoomAuthoritySheet extends ConsumerStatefulWidget {
  const _VoiceRoomAuthoritySheet({
    required this.room,
    required this.live,
    required this.perms,
    required this.isOwner,
  });

  final VoiceRoomEntity room;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final bool isOwner;

  @override
  ConsumerState<_VoiceRoomAuthoritySheet> createState() =>
      _VoiceRoomAuthoritySheetState();
}

class _VoiceRoomAuthoritySheetState extends ConsumerState<_VoiceRoomAuthoritySheet> {
  ChatRoomPresence? _selected;
  var _busy = false;

  String get _roomKey =>
      widget.room.apiRoomKey.isNotEmpty
          ? widget.room.apiRoomKey
          : widget.room.id;

  VoiceModerationNotifier get _mod =>
      ref.read(voiceModerationProvider(_roomKey).notifier);

  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final message = await action();
    if (mounted) setState(() => _busy = false);
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String?> _exec(Future<bool> Function() fn, String ok) async {
    try {
      final okResult = await fn();
      return okResult ? ok : 'İşlem başarısız';
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> _execKick(Future<String?> Function() fn) async {
    try {
      final msg = await fn();
      return msg ?? 'Kullanıcı odadan atıldı';
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  List<ChatRoomPresence> get _candidates {
    final selfId = ref.read(authControllerProvider).valueOrNull?.id;
    return widget.live.presence
        .where((p) => p.id.isNotEmpty && p.id != selfId)
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final perms = widget.perms;
    final selected = _selected;
    final modState = ref.watch(voiceModerationProvider(_roomKey));
    final loading = _busy || modState is AsyncLoading;
    final modErr =
        modState is AsyncError ? ApiException.userMessage(modState.error) : null;

    return DraggableScrollableSheet(
      initialChildSize: selected == null ? 0.72 : 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return VoiceGlass(
          borderRadius: 28,
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  if (selected != null)
                    IconButton(
                      onPressed: loading
                          ? null
                          : () => setState(() => _selected = null),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                    ),
                  Expanded(
                    child: Text(
                      selected == null ? 'Yetki Ver' : selected.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  ),
                ],
              ),
              if (modErr != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    modErr,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              Expanded(
                child: selected == null
                    ? _UserPickerList(
                        users: _candidates,
                        perms: perms,
                        onPick: (u) => setState(() => _selected = u),
                        scrollController: scrollController,
                      )
                    : _ActionPanel(
                        target: VoiceRoomModerationTarget.fromPresence(selected),
                        perms: perms,
                        isOwner: widget.isOwner,
                        loading: loading,
                        scrollController: scrollController,
                        onRole: (symbol, label) => _run(() async {
                          if (symbol == '%' &&
                              !perms.isSiteAdmin &&
                              !perms.isRoomOwner) {
                            return 'Admin yetkisi verme izniniz yok';
                          }
                          if (symbol == '+') {
                            await _mod.assignRoleSymbol(selected.id, '+');
                            return _exec(
                              () => _mod.grantVoice(selected.id),
                              '+V ses yetkisi verildi',
                            );
                          }
                          return _exec(
                            () => _mod.assignRoleSymbol(selected.id, symbol),
                            '$label yetkisi verildi',
                          );
                        }),
                        onMute: () => _run(
                          () => _exec(
                            () => _mod.muteUser(selected.id),
                            '${selected.displayName} sessize alındı',
                          ),
                        ),
                        onBan: () => _confirmAndRun(
                          title: 'Ban',
                          body: '${selected.displayName} banlansın mı?',
                          action: () => _exec(
                            () => _mod.banUser(selected.id),
                            'Kullanıcı banlandı',
                          ),
                        ),
                        onUnban: () => _run(
                          () => _exec(
                            () => _mod.unbanUser(selected.id),
                            'Ban kaldırıldı',
                          ),
                        ),
                        onKick: () => _run(
                          () => _execKick(
                            () => _mod.kickUser(selected.id),
                          ),
                        ),
                        onMicOff: () => _run(
                          () => _exec(
                            () => _mod.removeFromSeat(selected.id),
                            'Mikrofon kapatıldı (koltuktan indirildi)',
                          ),
                        ),
                        onMicOn: () => _run(
                          () => _exec(
                            () => _mod.grantVoice(selected.id),
                            'Mikrofon açıldı (koltuğa alındı)',
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndRun({
    required String title,
    required String body,
    required Future<String?> Function() action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(action);
  }
}

class _UserPickerList extends StatelessWidget {
  const _UserPickerList({
    required this.users,
    required this.perms,
    required this.onPick,
    required this.scrollController,
  });

  final List<ChatRoomPresence> users;
  final VoiceRoomPermissions perms;
  final ValueChanged<ChatRoomPresence> onPick;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
        child: Text('Odada başka kullanıcı yok', style: TextStyle(color: Colors.white60)),
      );
    }
    return ListView.separated(
      controller: scrollController,
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final u = users[i];
        final tone = VoiceModerationTargetColorResolver.resolve(
          actor: perms,
          target: u,
          kickAction: false,
        );
        final color = VoiceModerationTargetColorResolver.valueOf(tone);
        return Material(
          color: Colors.transparent,
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: color.withValues(alpha: 0.35)),
            ),
            tileColor: color.withValues(alpha: 0.12),
            leading: VoiceNeonAvatar(url: u.image, size: 40),
            title: Text(
              u.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            subtitle: Text(
              u.roleSymbol?.isNotEmpty == true
                  ? u.roleSymbol!
                  : (u.chatRole ?? 'dinleyici'),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            onTap: () => onPick(u),
          ),
        );
      },
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.target,
    required this.perms,
    required this.isOwner,
    required this.loading,
    required this.scrollController,
    required this.onRole,
    required this.onMute,
    required this.onBan,
    required this.onUnban,
    required this.onKick,
    required this.onMicOff,
    required this.onMicOn,
  });

  final VoiceRoomModerationTarget target;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final bool loading;
  final ScrollController scrollController;
  final void Function(String symbol, String label) onRole;
  final VoidCallback onMute;
  final VoidCallback onBan;
  final VoidCallback onUnban;
  final VoidCallback onKick;
  final VoidCallback onMicOff;
  final VoidCallback onMicOn;

  bool get _canRoles =>
      perms.canModerate || perms.isRoomOwner || perms.isSiteAdmin || isOwner;

  bool get _canAdmin => perms.isSiteAdmin || perms.isRoomOwner;

  @override
  Widget build(BuildContext context) {
    final roleActions = <_AuthAction>[
      if (_canRoles)
        _AuthAction(
          icon: Icons.mic_rounded,
          label: '+V',
          color: const Color(0xFF22C55E),
          onTap: loading ? null : () => onRole('+', '+V'),
        ),
      if (_canRoles)
        _AuthAction(
          icon: Icons.shield_rounded,
          label: '@',
          color: const Color(0xFF25F4EE),
          onTap: loading ? null : () => onRole('@', '@'),
        ),
      if (_canRoles && (perms.canBanUsers || isOwner))
        _AuthAction(
          icon: Icons.verified_user_rounded,
          label: '&',
          color: const Color(0xFFFF6B35),
          onTap: loading ? null : () => onRole('&', '&'),
        ),
      if (_canAdmin)
        _AuthAction(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Admin',
          color: VoiceRoomTokens.gold,
          onTap: loading ? null : () => onRole('%', 'Admin'),
        ),
    ];

    final modActions = <_AuthAction>[
      if (perms.canMuteUsers || isOwner)
        _AuthAction(
          icon: Icons.notifications_off_rounded,
          label: 'Sessize al',
          color: Colors.deepOrange,
          onTap: loading ? null : onMute,
        ),
      if (perms.canBanUsers || isOwner)
        _AuthAction(
          icon: Icons.block_rounded,
          label: 'Ban',
          color: Colors.red,
          onTap: loading ? null : onBan,
        ),
      if (perms.canBanUsers || isOwner)
        _AuthAction(
          icon: Icons.lock_open_rounded,
          label: 'Ban kaldır',
          color: Colors.teal,
          onTap: loading ? null : onUnban,
        ),
      if (perms.canKickUsers || isOwner)
        _AuthAction(
          icon: Icons.logout_rounded,
          label: 'Kanaldan at',
          color: const Color(0xFFB8860B),
          onTap: loading ? null : onKick,
        ),
      if (perms.canAssignSeats || perms.canGiveVoice || isOwner)
        _AuthAction(
          icon: Icons.mic_off_rounded,
          label: 'Mikrofon kapat',
          color: Colors.redAccent,
          onTap: loading ? null : onMicOff,
        ),
      if (perms.canAssignSeats || perms.canGiveVoice || isOwner)
        _AuthAction(
          icon: Icons.mic_rounded,
          label: 'Mikrofon aç',
          color: Colors.lightGreen,
          onTap: loading ? null : onMicOn,
        ),
    ];

    return ListView(
      controller: scrollController,
      children: [
        Row(
          children: [
            VoiceNeonAvatar(url: target.avatarUrl, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                target.username,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        if (roleActions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Yetki ver',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 8),
          _ActionGrid(actions: roleActions),
        ],
        if (modActions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Moderasyon',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 8),
          _ActionGrid(actions: modActions),
        ],
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

class _AuthAction {
  const _AuthAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_AuthAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        final a = actions[i];
        final enabled = a.onTap != null;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: a.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: a.color.withValues(alpha: enabled ? 0.2 : 0.08),
                border: Border.all(
                  color: a.color.withValues(alpha: enabled ? 0.45 : 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    a.icon,
                    size: 32,
                    color: enabled ? a.color : a.color.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: enabled
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
