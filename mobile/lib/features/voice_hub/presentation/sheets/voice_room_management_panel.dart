import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../vip_gold/domain/voice_room_access.dart';
import '../../../gifts/presentation/providers/gift_battle_providers.dart';
import '../../../gifts/presentation/providers/gift_goal_providers.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_ban_entry.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_ui_provider.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_glass.dart';
import '../widgets/premium/voice_neon_avatar.dart';
import 'voice_room_hub_settings.dart';
import 'voice_room_moderation_sheet.dart';
import 'voice_moderation_user_picker_sheet.dart';

enum _MgmtView { home, chat, users, room, penalties, userActions }

/// Oda Yönetim paneli — Sohbet, Kullanıcılar, Oda yönetimi, Cezalar.
Future<void> showVoiceRoomManagementPanel(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required bool isOwner,
  void Function(ChatRoomPresence user)? onUserTap,
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
  });

  final VoiceRoomEntity room;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final void Function(ChatRoomPresence user)? onUserTap;

  @override
  ConsumerState<_VoiceRoomManagementPanel> createState() =>
      _VoiceRoomManagementPanelState();
}

class _VoiceRoomManagementPanelState
    extends ConsumerState<_VoiceRoomManagementPanel> {
  _MgmtView _view = _MgmtView.home;
  ChatRoomPresence? _selectedUser;
  List<VoiceRoomBanEntry> _bans = const [];
  var _loadingBans = false;

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
    if (_view == _MgmtView.userActions) {
      setState(() {
        _view = _MgmtView.users;
        _selectedUser = null;
      });
      return;
    }
    setState(() => _view = _MgmtView.home);
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
                _MgmtView.chat => _chatView(scroll),
                _MgmtView.users => _usersView(scroll),
                _MgmtView.userActions => _userActionsView(),
                _MgmtView.room => _roomView(scroll),
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
      _MgmtView.home => 'Oda Yönetim paneli',
      _MgmtView.chat => 'Sohbet',
      _MgmtView.users => 'Kullanıcılar',
      _MgmtView.userActions => _selectedUser?.displayName ?? 'Kullanıcı',
      _MgmtView.room => 'Oda yönetimi',
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
    final tiles = [
      (Icons.chat_bubble_outline_rounded, 'Sohbet', _MgmtView.chat),
      (Icons.people_outline_rounded, 'Kullanıcılar', _MgmtView.users),
      (Icons.meeting_room_outlined, 'Oda yönetimi', _MgmtView.room),
      (Icons.gavel_outlined, 'Cezalar', _MgmtView.penalties),
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
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                if (t.$3 == _MgmtView.penalties) _loadBans();
                _go(t.$3);
              },
            ),
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
              await _snack(err ?? 'Sohbet temizlendi');
            },
          ),
        if (isOwner)
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded),
            title: const Text('Sahipligi devret'),
            onTap: () => _pickUserForTransfer(scroll),
          ),
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: const Text('Takma adı değiştir'),
          onTap: _changeNickname,
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
    final err = await _ctrl.assignRoleToUser(
      targetUserId: picked.id,
      roleSymbol: '~',
    );
    await _snack(err ?? 'Oda devredildi');
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
          onTap: () {
            setState(() {
              _selectedUser = u;
              _view = _MgmtView.userActions;
            });
          },
        );
      },
    );
  }

  Widget _userActionsView() {
    final u = _selectedUser;
    if (u == null) return const SizedBox.shrink();
    final canMod = perms.canModerate ||
        isOwner ||
        perms.canMuteUsers ||
        perms.canKickUsers ||
        perms.canBanUsers;
    if (!canMod) {
      return Center(
        child: TextButton(
          onPressed: () => widget.onUserTap?.call(u),
          child: const Text('Profili aç'),
        ),
      );
    }
    final target = VoiceRoomModerationTarget.fromPresence(u);
    final isDj = room.djUserIds.contains(u.id) ||
        _live.dj.djUsers.any((d) => d.id == u.id);

    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(8),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: [
        _actionTile('Sustur', Icons.mic_off_rounded, () => _muteUser(u.id)),
        _actionTile('Kanaldan at', Icons.logout_rounded, () => _kickUser(u.id)),
        _actionTile('Engelle', Icons.block_rounded, () => _banUser(u.id)),
        _actionTile('Yetki ver', Icons.admin_panel_settings_outlined,
            () => _showRolePicker(u)),
        if (target.isModerator || target.isSop || target.isSpeaker)
          _actionTile('Yetki kaldır', Icons.remove_moderator_outlined,
              () => _revokeRole(u)),
        _actionTile('Ban kaldır', Icons.lock_open_rounded, () => _unbanUser(u.id)),
        _actionTile('Detaylı moderasyon', Icons.more_horiz_rounded, () {
          Navigator.pop(context);
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
        }),
      ],
    );
  }

  Widget _actionTile(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: VoiceRoomTokens.neonBlue),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<void> _showRolePicker(ChatRoomPresence u) async {
    final sym = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF12082A),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Yetki seç', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            for (final e in const [
              ('+', '+V Ses'),
              ('@', 'Moderatör'),
              ('&', 'Yetkili'),
            ])
              ListTile(
                title: Text('${e.$1} ${e.$2}', style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, e.$1),
              ),
          ],
        ),
      ),
    );
    if (sym == null) return;
    final err = await _ctrl.assignRoleToUser(targetUserId: u.id, roleSymbol: sym);
    if (sym == '+') {
      for (var seat = 0; seat <= 14; seat++) {
        final seatErr = await _ctrl.assignSeat(seatIndex: seat, userId: u.id);
        if (seatErr == null) break;
      }
    }
    await _snack(err ?? 'Yetki verildi ($sym)');
  }

  Future<void> _revokeRole(ChatRoomPresence u) async {
    final err = await _ctrl.assignRoleToUser(targetUserId: u.id, roleSymbol: '+');
    await _snack(err ?? 'Yetki kaldırıldı');
  }

  Future<void> _muteUser(String userId) async {
    try {
      await ref.read(chatRoomRemoteProvider).muteUser(
            roomKey: room.liveKey,
            userId: userId,
            minutes: 30,
            reason: 'Oda moderasyonu',
          );
      await _ctrl.refresh();
      await _snack('Kullanıcı susturuldu');
    } catch (e) {
      await _snack(ApiException.userMessage(e));
    }
  }

  Future<void> _kickUser(String userId) async {
    final result = await _ctrl.kickUserModeration(userId: userId);
    await _snack(result?.feedbackMessage ?? 'Kullanıcı atıldı');
  }

  Future<void> _banUser(String userId) async {
    final err = await _ctrl.banUserModeration(userId: userId);
    await _snack(err ?? 'Kullanıcı engellendi (ban)');
  }

  Future<void> _unbanUser(String userId) async {
    final err = await _ctrl.unbanUserModeration(userId: userId);
    await _snack(err ?? 'Ban kaldırıldı');
  }

  Widget _roomView(ScrollController scroll) {
    final canBg = perms.canChangeBackground || isOwner;
    final isVip = room.isVipGoldRoom;

    return ListView(
      controller: scroll,
      children: [
        if (canBg) ...[
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Arkaplan resmini değiştir'),
            subtitle: const Text('Galeriden veya kameradan yükle'),
            onTap: () {
              Navigator.pop(context);
              showVoiceRoomBackgroundSheet(context, ref, room: room);
            },
          ),
          ListTile(
            leading: const Icon(Icons.collections_rounded),
            title: const Text('Hazır arkaplanlar'),
            onTap: _pickCatalogBackground,
          ),
        ] else
          const ListTile(
            title: Text('Arkaplan değiştirme yetkiniz yok'),
          ),
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
        if (isVip && (isOwner || perms.canManageRoom)) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_rounded),
            title: const Text('Oda şifresi (VIP)'),
            subtitle: const Text('Girenler şifreyi bilmeli'),
            onTap: _setRoomPassword,
          ),
        ],
      ],
    );
  }

  Future<void> _startGiftBattle() async {
    final seated = widget.live.presence
        .where((p) => p.seatIndex != null && p.id.isNotEmpty)
        .toList();
    if (seated.length < 2) {
      await _snack('Savaş için en az 2 koltukta kullanıcı olmalı');
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

  Future<void> _pickCatalogBackground() async {
    try {
      final urls = await _ctrl.fetchBackgrounds();
      if (!mounted || urls.isEmpty) {
        await _snack('Arkaplan listesi boş');
        return;
      }
      final picked = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF12082A),
        isScrollControlled: true,
        builder: (ctx) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.45,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: urls.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.pop(ctx, urls[i]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CanlifalNetworkImage(
                  url: urls[i],
                  thumbnailWidth: 240,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      );
      if (picked == null) return;
      final err = await _ctrl.setRoomBackground(picked);
      await _snack(err ?? 'Arkaplan güncellendi');
    } catch (e) {
      await _snack(ApiException.userMessage(e));
    }
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
                Navigator.pop(context);
                showVoiceModerationUserPicker(
                  context: context,
                  ref: ref,
                  room: room,
                  perms: perms,
                  action: VoiceModerationPickerAction.kick,
                  presence: _live.presence,
                );
              },
              icon: const Icon(Icons.person_remove_rounded),
              label: const Text('Kullanıcı at (kick)'),
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
