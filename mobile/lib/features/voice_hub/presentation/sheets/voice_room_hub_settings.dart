import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/widgets/lazy_list_views.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_ui_provider.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_glass.dart';
import '../widgets/premium/voice_neon_avatar.dart';
import 'voice_room_sheets.dart';
import 'voice_youtube_song_sheet.dart';

Future<void> showVoiceRoomHubSettingsSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required bool isOwner,
  void Function(ChatRoomPresence user)? onUserTap,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _HubSettingsSheet(
        room: room,
        live: live,
        perms: perms,
        isOwner: isOwner,
        onUserTap: onUserTap,
      ),
    ),
  );
}

class _HubSettingsSheet extends ConsumerStatefulWidget {
  const _HubSettingsSheet({
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
  ConsumerState<_HubSettingsSheet> createState() => _HubSettingsSheetState();
}

class _HubSettingsSheetState extends ConsumerState<_HubSettingsSheet> {
  List<String> _backgrounds = const [];
  var _loadingBg = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBackgrounds());
  }

  Future<void> _loadBackgrounds() async {
    if (_loadingBg || _backgrounds.isNotEmpty) return;
    setState(() => _loadingBg = true);
    try {
      final urls = await ref
          .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
          .fetchBackgrounds();
      if (mounted) setState(() => _backgrounds = urls);
    } finally {
      if (mounted) setState(() => _loadingBg = false);
    }
  }

  void _openRoomSettings() {
    Navigator.pop(context);
    showVoiceRoomSettingsSheet(
      context,
      ref,
      room: widget.room,
      isOwner: widget.isOwner,
      perms: widget.perms,
      presence: widget.live.presence,
      onUserTap: widget.onUserTap,
    );
  }

  void _openSongRequest() {
    Navigator.pop(context);
    showVoiceYoutubeSongSheet(context, ref, room: widget.room);
  }

  Future<void> _changeNickname() async {
    final controller = TextEditingController();
    try {
      final err = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Oda rumuzu'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Sohbette görünecek rumuz',
              border: OutlineInputBorder(),
            ),
            maxLength: 32,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
      if (!mounted || err == null) return;
      final message = await ref
          .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
          .updateRoomNickname(err);
      if (!mounted) return;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rumuz güncellendi')),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  void _openRoomCommands() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceGlass(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Oda Komutları',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Moderatör ve oda sahibi için (canlifal.com ile uyumlu)',
              style: TextStyle(
                fontSize: 11,
                color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            ..._roomCommands.map(
              (c) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(c.$2, color: VoiceRoomTokens.neonBlue, size: 20),
                title: Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(c.$3, style: const TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
                      .sendMessage(c.$1);
                  if (!context.mounted) return;
                  final liveErr =
                      ref.read(voiceRoomLiveProvider(widget.room.liveKey)).error;
                  if (liveErr != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(liveErr)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${c.$1} gönderildi')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _roomCommands = [
    ('!duyuru', Icons.campaign_rounded, 'Oda duyurusu yayınla'),
    ('!temizle', Icons.cleaning_services_rounded, 'Sohbet akışını temizle'),
    ('!kick', Icons.person_remove_rounded, 'Kullanıcıyı odadan çıkar'),
    ('!ban', Icons.block_rounded, 'Kullanıcıyı yasakla'),
    ('!unban', Icons.lock_open_rounded, 'Yasağı kaldır'),
    ('!dj', Icons.headphones_rounded, 'DJ yetkisi ver / al'),
    ('!muzik', Icons.queue_music_rounded, 'Müzik kuyruğunu yönet'),
  ];

  Future<void> _applyBackground(String url) async {
    final err = await ref
        .read(voiceRoomLiveProvider(widget.room.liveKey).notifier)
        .setRoomBackground(url);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Arka plan güncellendi')),
    );
  }

  void _openDjManage() {
    final canManage = widget.perms.canManageDj ||
        widget.perms.canManageRoom ||
        widget.perms.isRoomOwner ||
        widget.perms.isSiteAdmin ||
        widget.isOwner;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, scroll) => VoiceGlass(
          borderRadius: 24,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'DJ Yönetimi (${widget.live.dj.djCount}/${widget.live.dj.maxDj})',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 8),
              if (!canManage)
                Text(
                  'DJ eklemek için oda sahibi veya moderatör olun',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
                  ),
                ),
              Expanded(
                child: LazyListView(
                  controller: scroll,
                  itemCount: widget.live.presence.length,
                  itemBuilder: (context, index) {
                    final u = widget.live.presence[index];
                    final isDj = widget.live.dj.djUsers.any((d) => d.id == u.id);
                    return ListTile(
                      leading: VoiceNeonAvatar(url: u.image, size: 40),
                      title: Text(u.displayName),
                      subtitle: Text(isDj ? 'DJ' : (u.chatRole ?? 'dinleyici')),
                      trailing: canManage
                          ? IconButton(
                              icon: Icon(
                                isDj ? Icons.remove_circle_outline : Icons.add_circle_outline,
                                color: isDj ? AppThemeColors.liveRed : AppThemeColors.onlineGreen,
                              ),
                              onPressed: () async {
                                final ctrl = ref.read(
                                  voiceRoomLiveProvider(widget.room.liveKey).notifier,
                                );
                                final err = isDj
                                    ? await ctrl.removeRoomDj(u.id)
                                    : await ctrl.addRoomDj(u.id);
                                if (context.mounted) {
                                  if (err != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(err)),
                                    );
                                  } else {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isDj
                                              ? '${u.displayName} DJ listesinden çıkarıldı'
                                              : '${u.displayName} DJ yapıldı',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(voiceRoomUiProvider);
    final canBg = widget.perms.canChangeBackground;

    final tiles = <({IconData icon, String label, VoidCallback onTap})>[
      (
        icon: Icons.settings_rounded,
        label: 'Oda ayarları',
        onTap: _openRoomSettings,
      ),
      (
        icon: Icons.queue_music_rounded,
        label: 'Şarkı isteği',
        onTap: _openSongRequest,
      ),
      (
        icon: Icons.badge_rounded,
        label: 'Rumuz',
        onTap: _changeNickname,
      ),
      (
        icon: Icons.terminal_rounded,
        label: 'Komutlar',
        onTap: _openRoomCommands,
      ),
      (
        icon: Icons.headphones_rounded,
        label: 'DJ yönetimi',
        onTap: _openDjManage,
      ),
      (
        icon: Icons.people_rounded,
        label: 'Dinleyici listesi',
        onTap: () {
          Navigator.pop(context);
          showVoiceSpeakerListSheet(
            context,
            presence: widget.live.presence,
            room: widget.room,
            onUserTap: widget.onUserTap,
          );
        },
      ),
      if (canBg)
        (
          icon: Icons.wallpaper_rounded,
          label: 'Arka plan',
          onTap: _loadBackgrounds,
        ),
      (
        icon: ui.headphonesOn
            ? Icons.headset_rounded
            : Icons.headset_off_rounded,
        label: 'Hoparlör',
        onTap: () =>
            ref.read(voiceRoomUiProvider.notifier).toggleHeadphones(),
      ),
      (
        icon: ui.backgroundMusicEnabled
            ? Icons.music_note_rounded
            : Icons.music_off_rounded,
        label: 'Oda müziği',
        onTap: () =>
            ref.read(voiceRoomUiProvider.notifier).toggleBackgroundMusic(),
      ),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scroll) => VoiceGlass(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
        child: ListView(
          controller: scroll,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.92,
              ),
              itemCount: tiles.length,
              itemBuilder: (context, i) {
                final t = tiles[i];
                return Tooltip(
                  message: t.label,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: t.onTap,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          t.icon,
                          color: VoiceRoomTokens.neonBlue,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (canBg && _loadingBg)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (canBg && _backgrounds.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _backgrounds.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final url = _backgrounds[i];
                    return GestureDetector(
                      onTap: () => _applyBackground(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CanlifalNetworkImage(
                          url: url,
                          width: 160,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
