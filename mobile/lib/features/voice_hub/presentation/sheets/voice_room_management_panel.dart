import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../vip_gold/domain/voice_room_access.dart';
import '../../../gifts/presentation/providers/gift_battle_providers.dart';
import '../../../gifts/presentation/providers/gift_goal_providers.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_ban_entry.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../providers/chat_room_providers.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_room_ui_provider.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_room_permissions.dart';
import '../utils/voice_room_seat_capacity.dart';
import '../widgets/premium/voice_glass.dart';
import '../widgets/premium/voice_neon_avatar.dart';
import 'voice_room_commands_panel.dart';
import 'voice_room_hub_settings.dart';
import 'voice_room_menu_sheet.dart' show VoiceRoomMenuRole;
import 'voice_room_moderation_sheet.dart';
import 'voice_room_muted_users_sheet.dart';
import 'voice_room_sheets.dart';
import 'voice_room_voice_users_sheet.dart';
import 'voice_youtube_song_sheet.dart';
import 'voice_room_speak_queue_sheet.dart';

enum VoiceMgmtInitial { home, userMgmt, users, chatMgmt, roomMgmt, userSettings }

enum _MgmtView { home, userMgmt, chatMgmt, roomMgmt, userSettings, users, penalties }

/// Oda ayarları — Kullanıcı / Sohbet / Oda yönetimi / Kullanıcı ayarları.
Future<void> showVoiceRoomManagementPanel(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required bool isOwner,
  void Function(ChatRoomPresence user)? onUserTap,
  VoidCallback? onPkInvite,
  VoiceMgmtInitial initial = VoiceMgmtInitial.home,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(ctx),
      child: _VoiceRoomManagementPanel(
        room: room,
        live: live,
        perms: perms,
        isOwner: isOwner,
        onUserTap: onUserTap,
        onPkInvite: onPkInvite,
        initial: initial,
      ),
    ),
  );
}

class _VoiceRoomManagementPanel extends ConsumerStatefulWidget {
  const _VoiceRoomManagementPanel({
    required this.room,
    required this.live,
    required this.perms,
    required this.isOwner,
    this.onUserTap,
    this.onPkInvite,
    this.initial = VoiceMgmtInitial.home,
  });

  final VoiceRoomEntity room;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final void Function(ChatRoomPresence user)? onUserTap;
  final VoidCallback? onPkInvite;
  final VoiceMgmtInitial initial;

  @override
  ConsumerState<_VoiceRoomManagementPanel> createState() =>
      _VoiceRoomManagementPanelState();
}

class _VoiceRoomManagementPanelState
    extends ConsumerState<_VoiceRoomManagementPanel> {
  late _MgmtView _view = _mapInitial(widget.initial);
  List<VoiceRoomBanEntry> _bans = const [];
  var _loadingBans = false;

  static _MgmtView _mapInitial(VoiceMgmtInitial initial) => switch (initial) {
        VoiceMgmtInitial.home => _MgmtView.home,
        VoiceMgmtInitial.userMgmt => _MgmtView.userMgmt,
        VoiceMgmtInitial.users => _MgmtView.users,
        VoiceMgmtInitial.chatMgmt => _MgmtView.chatMgmt,
        VoiceMgmtInitial.roomMgmt => _MgmtView.roomMgmt,
        VoiceMgmtInitial.userSettings => _MgmtView.userSettings,
      };

  VoiceRoomEntity get room => widget.room;
  VoiceRoomPermissions get perms => widget.perms;
  bool get isOwner => widget.isOwner;

  VoiceRoomLiveController get _ctrl =>
      ref.read(voiceRoomLiveProvider(room.liveKey).notifier);

  VoiceRoomLiveState get _live =>
      ref.watch(voiceRoomLiveProvider(room.liveKey));

  Future<void> _snack(String text) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _loadBans() async {
    if (_loadingBans) return;
    setState(() => _loadingBans = true);
    try {
      final list = await _ctrl.fetchModerationBans();
      if (mounted) setState(() => _bans = list);
    } finally {
      if (mounted) setState(() => _loadingBans = false);
    }
  }

  void _go(_MgmtView view) => setState(() => _view = view);

  void _back() {
    if (_view == _MgmtView.users || _view == _MgmtView.penalties) {
      setState(() => _view = _MgmtView.userMgmt);
      return;
    }
    if (_view != _MgmtView.home) {
      setState(() => _view = _MgmtView.home);
      return;
    }
  }

  void _closeAndVoid(VoidCallback action) {
    final ctx = context;
    Navigator.pop(ctx);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctx.mounted) return;
      action();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scroll) => VoiceGlass(
        borderRadius: 24,
        padding: EdgeInsets.fromLTRB(12, 12, 12, bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 8),
            Expanded(
              child: switch (_view) {
                _MgmtView.home => _homeView(scroll),
                _MgmtView.userMgmt => _userMgmtHub(scroll),
                _MgmtView.chatMgmt => _chatView(scroll),
                _MgmtView.roomMgmt => _roomView(scroll),
                _MgmtView.userSettings => _userSettingsView(scroll),
                _MgmtView.users => _usersView(scroll),
                _MgmtView.penalties => _penaltiesView(scroll),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final title = switch (_view) {
      _MgmtView.home => 'Ayarlar',
      _MgmtView.userMgmt => 'Kullanıcı yönetimi',
      _MgmtView.chatMgmt => 'Sohbet yönetimi',
      _MgmtView.roomMgmt => 'Oda yönetimi',
      _MgmtView.userSettings => 'Kullanıcı ayarları',
      _MgmtView.users => 'Kullanıcılar',
      _MgmtView.penalties => 'Cezalar',
    };
    return Row(
      children: [
        if (_view != _MgmtView.home)
          IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _homeView(ScrollController scroll) {
    final tiles = <(IconData, String, String, _MgmtView, bool)>[
      if (perms.canManageUsers)
        (
          Icons.people_alt_outlined,
          'Kullanıcı yönetimi',
          'Yetki, susturma, ban, kick',
          _MgmtView.userMgmt,
          true,
        ),
      if (perms.canManageChat)
        (
          Icons.chat_bubble_outline_rounded,
          'Sohbet yönetimi',
          'Duyuru, temizle, oda sessize',
          _MgmtView.chatMgmt,
          true,
        ),
      if (perms.canManageRoomSettings)
        (
          Icons.meeting_room_outlined,
          'Oda yönetimi',
          'Arkaplan, PK, müzik, hediye savaşı',
          _MgmtView.roomMgmt,
          true,
        ),
      (
        Icons.person_outline_rounded,
        'Kullanıcı ayarları',
        'Efektler, rumuz, bildirimler',
        _MgmtView.userSettings,
        true,
      ),
    ];

    return ListView(
      controller: scroll,
      children: [
        for (final t in tiles)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.15),
            child: ListTile(
              leading: Icon(t.$1, color: VoiceRoomTokens.neonBlue),
              title: Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(
                t.$3,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                if (t.$4 == _MgmtView.userMgmt) _loadBans();
                _go(t.$4);
              },
            ),
          ),
      ],
    );
  }

  Widget _userMgmtHub(ScrollController scroll) {
    return ListView(
      controller: scroll,
      children: [
        _hubTile(
          Icons.people_outline_rounded,
          'Odadaki kullanıcılar',
          'Ses ver, koltuk, yetki, kanaldan at',
          () => _go(_MgmtView.users),
        ),
        _hubTile(
          Icons.gavel_outlined,
          'Cezalar',
          'Ban, kick, sessize alınanlar',
          () {
            _loadBans();
            _go(_MgmtView.penalties);
          },
        ),
        if (perms.canMuteUsers || isOwner)
          _hubTile(
            Icons.volume_off_rounded,
            'Sessize alınmış kullanıcılar',
            'Susturma listesi',
            () => _closeAndVoid(() {
              showVoiceMutedUsersSheet(
                context: context,
                ref: ref,
                roomKey: room.liveKey,
                presence: _live.presence,
                perms: perms,
              );
            }),
          ),
        _hubTile(
          Icons.headset_mic_rounded,
          'Seste olanlar',
          'Ses kanalındaki kullanıcılar (voice API)',
          () => _closeAndVoid(() {
            showVoiceRoomVoiceUsersSheet(
              context,
              ref: ref,
              liveKey: room.liveKey,
              onUserTap: widget.onUserTap,
            );
          }),
        ),
        if (perms.canAssignSeats || isOwner || perms.isSiteAdmin)
          _hubTile(
            Icons.record_voice_over_rounded,
            'Konuşma sırası',
            'El kaldıranlar ve dinleyici kuyruğu',
            () => _closeAndVoid(() {
              showVoiceSpeakQueueSheet(
                context,
                ref,
                room: room,
                live: _live,
                perms: perms,
              );
            }),
          ),
      ],
    );
  }

  Widget _hubTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.12),
      child: ListTile(
        leading: Icon(icon, color: VoiceRoomTokens.neonBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Widget _userSettingsView(ScrollController scroll) {
    final ui = ref.watch(voiceRoomUiProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final role = VoiceRoomMenuRole.label(perms, user: user, live: _live);

    return ListView(
      controller: scroll,
      children: [
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: const Text('Rumuzunuz'),
          subtitle: Text(role),
        ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Takma adı değiştir'),
          onTap: () async {
            await _changeNickname();
            if (mounted) Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.auto_awesome_outlined),
          title: const Text('Efektler ve görünüm'),
          onTap: () => _closeAndVoid(() => showVoiceEffectsSheet(context, ref)),
        ),
        SwitchListTile(
          title: const Text('Bildirim sesi'),
          subtitle: const Text('Giriş ve oda bildirimleri'),
          value: ui.chatNotificationSoundEnabled,
          onChanged: (_) {
            ref.read(voiceRoomUiProvider.notifier).toggleChatNotificationSound();
          },
        ),
        SwitchListTile(
          title: const Text('Hediye animasyonları'),
          value: ui.giftAnimationsEnabled,
          onChanged: (_) {
            ref.read(voiceRoomUiProvider.notifier).toggleGiftAnimations();
          },
        ),
        if (!_selfOnSeat(user))
          ListTile(
            leading: Icon(
              ui.requestSpeakPending
                  ? Icons.hourglass_top_rounded
                  : Icons.pan_tool_alt_rounded,
              color: VoiceRoomTokens.neonPink,
            ),
            title: Text(
              ui.requestSpeakPending
                  ? 'Konuşma isteğini iptal'
                  : 'Konuşma isteği gönder',
            ),
            subtitle: Text(
              ui.requestSpeakPending
                  ? 'Moderatör onayı bekleniyor'
                  : 'Onay sonrası koltuğa alınırsınız',
            ),
            onTap: () async {
              final pending = ui.requestSpeakPending;
              final err = pending
                  ? await _ctrl.cancelSpeakRequest()
                  : await _ctrl.requestSpeak();
              await _snack(
                err ??
                    (pending
                        ? 'Konuşma isteği iptal edildi'
                        : 'Konuşma isteği gönderildi'),
              );
            },
          ),
        ListTile(
          leading: const Icon(Icons.diamond_outlined, color: VoiceRoomTokens.gold),
          title: const Text('Jeton yükle'),
          onTap: () => _closeAndVoid(() => openJetonStore(context, ref: ref)),
        ),
      ],
    );
  }

  Widget _chatView(ScrollController scroll) {
    final ui = ref.watch(voiceRoomUiProvider);
    final roomMuted = _live.roomMuted;
    final canMod = perms.canModerate || isOwner || perms.isSiteAdmin;

    return ListView(
      controller: scroll,
      children: [
        if (canMod || perms.canMuteRoom)
          SwitchListTile(
            title: const Text('Odayı sessize al'),
            subtitle: Text(roomMuted ? 'Oda şu an sessiz' : 'Oda sesi açık'),
            value: roomMuted,
            onChanged: (v) async {
              final err = await _ctrl.toggleRoomMute(mute: v);
              if (err != null) {
                await _snack(err);
              } else {
                await _snack(v ? 'Oda sessize alındı' : 'Oda sesi açıldı');
              }
            },
          ),
        SwitchListTile(
          title: const Text('Bildirim sesini aç'),
          subtitle: const Text('Giriş ve oda bildirimleri'),
          value: ui.chatNotificationSoundEnabled,
          onChanged: (_) => ref
              .read(voiceRoomUiProvider.notifier)
              .toggleChatNotificationSound(),
        ),
        if (canMod)
          ListTile(
            leading: const Icon(Icons.cleaning_services_rounded),
            title: const Text('Tüm mesajları temizle'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sohbeti temizle'),
                  content: const Text('Tüm mesajlar silinsin mi?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('İptal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Temizle'),
                    ),
                  ],
                ),
              );
              if (ok != true) return;
              final err = await _ctrl.clearChatAsModerator();
              if (!mounted) return;
              Navigator.pop(context);
              await _snack(err ?? 'Sohbet temizlendi');
            },
          ),
        if (canMod || isOwner)
          ListTile(
            leading: const Icon(Icons.terminal_rounded),
            title: const Text('Oda komutları'),
            subtitle: const Text('!duyuru, !kick, !ban, müzik isteği'),
            onTap: () => _closeAndVoid(() {
              showVoiceRoomCommandsPanel(
                context,
                ref,
                room: room,
                perms: perms,
                isOwner: isOwner,
              );
            }),
          ),
        if (isOwner)
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded),
            title: const Text('Sahipligi devret'),
            onTap: () => _pickUserForTransfer(scroll),
          ),
      ],
    );
  }

  Future<void> _pickUserForTransfer(ScrollController scroll) async {
    final users = _live.presence
        .where((p) => p.id != ref.read(authControllerProvider).valueOrNull?.id)
        .toList();
    if (users.isEmpty) {
      await _snack('Devredilecek kullanıcı yok');
      return;
    }
    final picked = await showModalBottomSheet<ChatRoomPresence>(
      context: context,
      backgroundColor: const Color(0xFF12082A),
      builder: (ctx) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: users.length,
          itemBuilder: (_, i) {
            final u = users[i];
            return ListTile(
              leading: VoiceNeonAvatar(url: u.image, size: 36),
              title: Text(u.displayName, style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, u),
            );
          },
        ),
      ),
    );
    if (picked == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sahipligi devret'),
        content: Text('${picked.displayName} oda sahibi yapılsın mı?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Devret')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(chatRoomRemoteProvider).transferOwnership(
            roomKey: widget.room.apiRoomKey.isNotEmpty
                ? widget.room.apiRoomKey
                : widget.room.id,
            newOwnerId: picked.id,
          );
      await _ctrl.refresh();
      await _snack('Oda ${picked.displayName} kullanıcısına devredildi');
    } catch (e) {
      await _snack(ApiException.userMessage(e));
    }
  }

  Future<void> _changeNickname() async {
    final controller = TextEditingController();
    try {
      final nick = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Takma ad (rumuz)'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Sohbette görünecek ad',
              border: OutlineInputBorder(),
            ),
            maxLength: 32,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
      if (nick == null) return;
      final err = await _ctrl.updateRoomNickname(nick);
      await _snack(err ?? 'Takma ad güncellendi');
    } finally {
      controller.dispose();
    }
  }

  Widget _usersView(ScrollController scroll) {
    final users = [..._live.presence]
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    if (users.isEmpty) {
      return const Center(child: Text('Odada kullanıcı yok'));
    }
    return ListView.builder(
      controller: scroll,
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u = users[i];
        final sym = u.roleSymbol?.trim();
        return ListTile(
          leading: VoiceNeonAvatar(url: u.image, size: 40),
          title: Text(u.displayName),
          subtitle: Text(
            [if (sym != null && sym.isNotEmpty) sym, u.chatRole ?? 'dinleyici']
                .join(' · '),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _openUserModeration(u),
        );
      },
    );
  }

  void _openUserModeration(ChatRoomPresence u) {
    final canMod = perms.canModerate ||
        isOwner ||
        perms.canMuteUsers ||
        perms.canKickUsers ||
        perms.canBanUsers ||
        perms.canGiveVoice ||
        perms.canGiveOp ||
        perms.canGiveSop ||
        perms.canAssignSeats;
    if (!canMod) {
      widget.onUserTap?.call(u);
      return;
    }
    final target = VoiceRoomModerationTarget.fromPresence(u);
    final isDj = room.djUserIds.contains(u.id) ||
        _live.dj.djUsers.any((d) => d.id == u.id);
    _closeAndVoid(() {
      showVoiceRoomModerationSheet(
        context: context,
        ref: ref,
        room: room,
        targetUser: target,
        isOwnerOrMod: true,
        perms: perms,
        isOwner: isOwner,
        isTargetDj: isDj,
      );
    });
  }

  Widget _roomView(ScrollController scroll) {
    final canBg = perms.canChangeBackground || isOwner;
    final pk = ref.watch(pkBattleRemoteProvider);
    final pkLive = isPkBattleLive(pk);
    final roomKey = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;

    return ListView(
      controller: scroll,
      children: [
        ListTile(
          leading: Icon(
            pkLive ? Icons.flash_on_rounded : Icons.sports_mma_rounded,
            color: VoiceRoomTokens.neonPink,
          ),
          title: Text(pkLive ? 'PK savaşı' : 'PK daveti'),
          onTap: () => _closeAndVoid(() {
            if (pkLive) {
              context.push('/voice-room/$roomKey/pk', extra: room);
            } else if (widget.onPkInvite != null) {
              widget.onPkInvite!();
            } else {
              context.push('/voice-room/$roomKey/pk-invite', extra: room);
            }
          }),
        ),
        if (perms.canManageDj || isOwner || perms.canModerate)
          ListTile(
            leading: const Icon(Icons.library_music_rounded),
            title: const Text('Müzik kontrolü'),
            subtitle: const Text('Şarkı isteği (video/ses) ve DJ'),
            onTap: () => _closeAndVoid(() {
              showVoiceMusicControlHub(
                context,
                ref,
                room: room,
                perms: perms,
                isOwner: isOwner,
              );
            }),
          ),
        ListTile(
          leading: const Icon(Icons.music_note_rounded),
          title: const Text('Şarkı isteği'),
          subtitle: const Text('Video (CDN) veya ses (YouTube API)'),
          onTap: () => _closeAndVoid(() {
            showVoiceYoutubeSongSheet(context, ref, room: room);
          }),
        ),
        if (canBg)
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Arkaplan'),
            subtitle: const Text('Sunucudaki hazır görseller veya yükle'),
            onTap: () {
              Navigator.pop(context);
              showVoiceRoomBackgroundSheet(context, ref, room: room);
            },
          )
        else
          const ListTile(
            title: Text('Arkaplan değiştirme yetkiniz yok'),
          ),
        if (isOwner || perms.canManageRoom) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: const Text('Oda adı ve açıklama'),
            subtitle: Text(room.displayTitle),
            onTap: _editRoomDetails,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline_rounded),
            title: const Text('Oda kilidi'),
            subtitle: Text(
              room.isLocked == true || room.hasPassword == true
                  ? 'Giriş kısıtlı'
                  : 'Herkes girebilir',
            ),
            value: room.isLocked == true,
            onChanged: (v) => unawaited(_setRoomLocked(v)),
          ),
          ListTile(
            leading: const Icon(Icons.event_seat_rounded),
            title: const Text('Koltuk sayısı'),
            subtitle: Text(
              '${_live.roomSeatCount ?? room.seatCount ?? kDefaultVoiceSeatCount} mikrofon',
            ),
            onTap: _pickSeatCount,
          ),
          ListTile(
            leading: const Icon(Icons.groups_rounded),
            title: const Text('Maksimum kullanıcı'),
            subtitle: Text(
              '${_live.roomMaxUsers ?? room.maxUsers ?? 15} kişi',
            ),
            onTap: _pickMaxUsers,
          ),
        ],
        if (isOwner || perms.canManageRoom) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFFF7043)),
            title: const Text('Hediye Savaşı Başlat'),
            subtitle: const Text('Koltuktakiler yarışır (1/3/5/10 dk)'),
            onTap: _startGiftBattle,
          ),
          ListTile(
            leading: const Icon(Icons.flag_rounded, color: Color(0xFF66E36F)),
            title: const Text('Hediye Hedefi Belirle'),
            subtitle: const Text('Toplanınca kutlama tetiklenir'),
            onTap: _startGiftGoal,
          ),
        ],
        if (isOwner || perms.canManageRoom) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_rounded),
            title: const Text('Giriş şifresi'),
            subtitle: const Text('Odaya giriş için şifre belirle'),
            onTap: _setRoomPassword,
          ),
        ],
      ],
    );
  }

  Future<void> _startGiftBattle() async {
    // Katılımcı: önce koltuktakiler; koltuk verisi yoksa/azsa odadaki tüm
    // kullanıcılar. (seatIndex her odada dolmayabiliyor → eskiden hep "2
    // koltukta kullanıcı" deyip başlamıyordu.)
    final present =
        widget.live.presence.where((p) => p.id.isNotEmpty).toList();
    final seatedUsers =
        present.where((p) => p.seatIndex != null).toList();
    final seated = seatedUsers.length >= 2 ? seatedUsers : present;
    if (seated.length < 2) {
      await _snack('Savaş için odada en az 2 kişi olmalı');
      return;
    }
    final duration = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF12082A),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Savaş süresi',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ),
            for (final opt in const [
              (60, '1 dakika'),
              (180, '3 dakika'),
              (300, '5 dakika'),
              (600, '10 dakika'),
            ])
              ListTile(
                leading: const Icon(Icons.timer_rounded, color: Colors.white70),
                title: Text(opt.$2, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, opt.$1),
              ),
          ],
        ),
      ),
    );
    if (duration == null || !mounted) return;
    try {
      final contextId = widget.room.apiRoomKey.isNotEmpty
          ? widget.room.apiRoomKey
          : widget.room.id;
      final battle = await ref.read(giftBattleRemoteProvider).startBattle(
            context: 'voice_room',
            contextId: contextId,
            durationSec: duration,
            participants: [
              for (final p in seated)
                (id: p.id, name: p.displayName),
            ],
          );
      if (battle != null) {
        ref
            .read(giftBattleProvider(
                    (context: 'voice_room', contextId: contextId))
                .notifier)
            .adopt(battle);
      }
      await _snack('Hediye savaşı başladı!');
    } catch (e) {
      await _snack(ApiException.userMessage(e));
    }
  }

  Future<void> _startGiftGoal() async {
    final target = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF12082A),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Hedef jeton miktarı',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ),
            for (final opt in const [
              (10000, '10K jeton'),
              (50000, '50K jeton'),
              (100000, '100K jeton'),
              (500000, '500K jeton'),
            ])
              ListTile(
                leading:
                    const Icon(Icons.flag_rounded, color: Color(0xFF66E36F)),
                title: Text(opt.$2, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, opt.$1),
              ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;
    try {
      final contextId = widget.room.apiRoomKey.isNotEmpty
          ? widget.room.apiRoomKey
          : widget.room.id;
      final goal = await ref.read(giftGoalRemoteProvider).createGoal(
            context: 'voice_room',
            contextId: contextId,
            title: 'Hedef: ${_fmtCoins(target)} jeton',
            targetAmount: target,
          );
      if (goal != null) {
        ref
            .read(giftGoalProvider(
                    (context: 'voice_room', contextId: contextId))
                .notifier)
            .adopt(goal);
      }
      await _snack('Hediye hedefi belirlendi!');
    } catch (e) {
      await _snack(ApiException.userMessage(e));
    }
  }

  static String _fmtCoins(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v';
  }

  bool _selfOnSeat(UserEntity? user) {
    final id = user?.id;
    if (id == null || id.isEmpty) return false;
    for (final p in _live.presence) {
      if (p.id == id && p.seatIndex != null) return true;
    }
    return false;
  }

  Future<void> _editRoomDetails() async {
    final nameCtrl = TextEditingController(text: room.displayTitle);
    final descCtrl = TextEditingController(text: room.descTr ?? '');
    final rulesCtrl = TextEditingController(text: room.rulesTr ?? '');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Oda bilgileri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Oda adı',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 64,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 280,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rulesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Oda kuralları',
                    border: OutlineInputBorder(),
                    hintText: 'Sohbette kayan kurallar metni',
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      final err = await _ctrl.updateRoomDetails(
        name: nameCtrl.text,
        description: descCtrl.text,
        rules: rulesCtrl.text,
      );
      await _snack(err ?? 'Oda bilgileri güncellendi');
    } finally {
      nameCtrl.dispose();
      descCtrl.dispose();
      rulesCtrl.dispose();
    }
  }

  Future<void> _setRoomLocked(bool locked) async {
    final err = await _ctrl.setRoomLocked(locked);
    if (err != null) {
      await _snack(err);
      return;
    }
    await _snack(locked ? 'Oda kilitlendi' : 'Oda kilidi kaldırıldı');
  }

  Future<void> _pickSeatCount() async {
    final current =
        _live.roomSeatCount ?? room.seatCount ?? kDefaultVoiceSeatCount;
    final options = const [8, 10, 12, 15];
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Koltuk sayısı'),
        children: options
            .map(
              (n) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, n),
                child: Row(
                  children: [
                    if (n == current)
                      const Icon(Icons.check_rounded, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text('$n mikrofon'),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (picked == null || picked == current) return;
    final err = await _ctrl.updateRoomCapacity(seatCount: picked);
    await _snack(err ?? 'Koltuk sayısı $picked olarak güncellendi');
  }

  Future<void> _pickMaxUsers() async {
    final current = _live.roomMaxUsers ?? room.maxUsers ?? 15;
    final options = const [15, 25, 50, 100];
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Maksimum kullanıcı'),
        children: options
            .map(
              (n) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, n),
                child: Row(
                  children: [
                    if (n == current)
                      const Icon(Icons.check_rounded, size: 20)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text('$n kişi'),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (picked == null || picked == current) return;
    final err = await _ctrl.updateRoomCapacity(maxUsers: picked);
    await _snack(err ?? 'Maksimum kullanıcı $picked olarak güncellendi');
  }

  Future<void> _setRoomPassword() async {
    final controller = TextEditingController();
    try {
      final pass = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Oda şifresi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni şifre (boş = kaldır)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
      if (pass == null) return;
      final err = await _ctrl.setRoomPassword(
        password: pass.trim().isEmpty ? null : pass.trim(),
      );
      await _snack(err ?? (pass.trim().isEmpty ? 'Şifre kaldırıldı' : 'Oda şifresi kaydedildi'));
    } finally {
      controller.dispose();
    }
  }

  Widget _penaltiesView(ScrollController scroll) {
    final muted = _live.presence.where((p) => p.isMuted).toList();
    final kicked = _live.messages
        .where((m) {
          final c = m.content.toLowerCase();
          return c.contains('atıldı') || c.contains('kick');
        })
        .toList()
        .reversed
        .take(30)
        .toList();

    return ListView(
      controller: scroll,
      children: [
        _sectionHeader('Sessize alınanlar'),
        if (muted.isEmpty)
          const _EmptyHint('Sessize alınmış kullanıcı yok')
        else
          ...muted.map(
            (u) => ListTile(
              leading: VoiceNeonAvatar(url: u.image, size: 36),
              title: Text(u.displayName),
              trailing: (perms.canMuteUsers || isOwner)
                  ? TextButton(
                      onPressed: () async {
                        final err = await _ctrl.unmuteUserModeration(userId: u.id);
                        await _snack(err ?? 'Susturma kaldırıldı');
                      },
                      child: const Text('Aç'),
                    )
                  : null,
            ),
          ),
        const SizedBox(height: 12),
        _sectionHeader('Banlı kullanıcılar'),
        if (_loadingBans)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_bans.isEmpty)
          const _EmptyHint('Banlı kullanıcı yok')
        else
          ..._bans.map(
            (b) => ListTile(
              title: Text(b.displayName.isNotEmpty ? b.displayName : b.userId),
              subtitle: Text(b.reason ?? ''),
              trailing: (perms.canBanUsers || isOwner)
                  ? TextButton(
                      onPressed: () async {
                        final err = await _ctrl.unbanUserModeration(userId: b.userId);
                        await _loadBans();
                        await _snack(err ?? 'Ban kaldırıldı');
                      },
                      child: const Text('Ban kaldır'),
                    )
                  : null,
            ),
          ),
        const SizedBox(height: 12),
        _sectionHeader('Kicklenenler'),
        if (kicked.isEmpty)
          const _EmptyHint('Son kick kaydı yok')
        else
          ...kicked.map(
            (m) => ListTile(
              dense: true,
              title: Text(m.content, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(m.createdAt.toString().substring(0, 16)),
            ),
          ),
        if (perms.canKickUsers || isOwner)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () {
                _go(_MgmtView.users);
              },
              icon: const Icon(Icons.people_outline_rounded),
              label: const Text('Kullanıcı seç ve kanaldan at'),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: VoiceRoomTokens.neonBlue.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
      ),
    );
  }
}
