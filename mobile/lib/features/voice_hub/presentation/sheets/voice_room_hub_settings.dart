import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    builder: (ctx) => _HubSettingsSheet(
      room: room,
      live: live,
      perms: perms,
      isOwner: isOwner,
      onUserTap: onUserTap,
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
          .read(voiceRoomLiveProvider(widget.room).notifier)
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
                      .read(voiceRoomLiveProvider(widget.room).notifier)
                      .sendMessage(c.$1);
                  if (!context.mounted) return;
                  final liveErr =
                      ref.read(voiceRoomLiveProvider(widget.room)).error;
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
        .read(voiceRoomLiveProvider(widget.room).notifier)
        .setRoomBackground(url);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Arka plan güncellendi')),
    );
  }

  void _openDjManage() {
    final canManage = widget.perms.canManageDj;
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
                child: ListView(
                  controller: scroll,
                  children: widget.live.presence.map((u) {
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
                                  voiceRoomLiveProvider(widget.room).notifier,
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
                  }).toList(),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Ayarlar',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: VoiceRoomTokens.neonPurple),
              title: const Text('Oda ayarları'),
              subtitle: const Text('Mesajlar, müzik, moderasyon'),
              onTap: _openRoomSettings,
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded, color: AppThemeColors.accentPink),
              title: const Text('Şarkı isteği'),
              subtitle: Text(
                'YouTube ara · ${widget.live.dj.musicRequestCost} jeton / istek',
              ),
              onTap: _openSongRequest,
            ),
            ListTile(
              leading: const Icon(Icons.terminal_rounded, color: VoiceRoomTokens.neonBlue),
              title: const Text('Oda komutları'),
              subtitle: const Text('Moderasyon komutları'),
              onTap: _openRoomCommands,
            ),
            ListTile(
              leading: const Icon(Icons.headphones_rounded, color: AppThemeColors.coinGold),
              title: Text('DJ (${widget.live.dj.djCount}/${widget.live.dj.maxDj})'),
              subtitle: const Text('DJ ekle veya çıkar'),
              onTap: _openDjManage,
            ),
            if (canBg) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.wallpaper_rounded),
                title: const Text('Oda arka planı'),
                subtitle: const Text('Siteden görsel seç'),
                onTap: _loadBackgrounds,
              ),
              if (_loadingBg)
                const Center(child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ))
              else if (_backgrounds.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _backgrounds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final url = _backgrounds[i];
                      return GestureDetector(
                        onTap: () => _applyBackground(url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: url,
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
            const Divider(),
            SwitchListTile(
              title: const Text('Hoparlör modu'),
              subtitle: const Text('Kulaklık / hoparlör'),
              value: ui.headphonesOn,
              onChanged: (_) {
                ref.read(voiceRoomUiProvider.notifier).toggleHeadphones();
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_rounded),
              title: const Text('Dinleyici listesi'),
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
          ],
        ),
      ),
    );
  }
}
