import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_ui_provider.dart';
import '../utils/voice_room_permissions.dart';
import '../theme/voice_room_tokens.dart';
import '../widgets/premium/voice_glass.dart';
import '../widgets/premium/voice_neon_avatar.dart';
import '../widgets/voice_room_gift_sheet.dart';

Future<void> showVoiceSpeakerListSheet(
  BuildContext context, {
  required List<ChatRoomPresence> presence,
  required VoiceRoomEntity room,
  void Function(ChatRoomPresence user)? onUserTap,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SpeakerListSheet(
      presence: presence,
      room: room,
      onUserTap: onUserTap,
    ),
  );
}

Future<void> showVoiceEffectsSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Consumer(
      builder: (_, ref, _) => _EffectsSheet(
        state: ref.watch(voiceRoomUiProvider),
        notifier: ref.read(voiceRoomUiProvider.notifier),
      ),
    ),
  );
}

Future<void> showVoiceRequestSpeakSheet(
  BuildContext context,
  WidgetRef ref, {
  required bool pending,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RequestSpeakSheet(
      pending: pending,
      onToggle: () {
        ref.read(voiceRoomUiProvider.notifier).toggleRequestSpeak();
        Navigator.pop(ctx);
      },
    ),
  );
}

Future<void> showVoiceRoomSettingsSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required bool isOwner,
  required VoiceRoomPermissions perms,
  required List<ChatRoomPresence> presence,
  void Function(ChatRoomPresence user)? onUserTap,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Consumer(
      builder: (_, ref, _) => _RoomSettingsSheet(
        room: room,
        isOwner: isOwner,
        perms: perms,
        presence: presence,
        onUserTap: onUserTap,
        state: ref.watch(voiceRoomUiProvider),
        notifier: ref.read(voiceRoomUiProvider.notifier),
      ),
    ),
  );
}

Future<void> showVoiceUserProfileSheet(
  BuildContext context, {
  required ChatRoomPresence user,
  required bool isOwner,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _UserProfileSheet(user: user, isOwner: isOwner),
  );
}

Future<void> showVoiceMoreMenuSheet(
  BuildContext context, {
  required WidgetRef ref,
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required VoidCallback onSettings,
  required VoidCallback onSpeakers,
  required VoidCallback onShare,
  required VoidCallback onBackgroundMusic,
  VoidCallback? onPickBackground,
}) {
  final ui = ref.read(voiceRoomUiProvider);
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => VoiceGlass(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.people_rounded),
            title: const Text('Konuşmacı listesi'),
            onTap: () {
              Navigator.pop(ctx);
              onSpeakers();
            },
          ),
          ListTile(
            leading: const Icon(Icons.music_note_rounded),
            title: Text(
              ui.backgroundMusicEnabled
                  ? 'Arka plan müziğini kapat'
                  : 'Arka plan müziği',
            ),
            onTap: () {
              Navigator.pop(ctx);
              onBackgroundMusic();
            },
          ),
          if (onPickBackground != null)
            ListTile(
              leading: const Icon(Icons.wallpaper_rounded),
              title: const Text('Oda arka plan resmi'),
              onTap: () {
                Navigator.pop(ctx);
                onPickBackground();
              },
            ),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Oda ayarları'),
            onTap: () {
              Navigator.pop(ctx);
              onSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Odayı paylaş'),
            onTap: () {
              Navigator.pop(ctx);
              onShare();
            },
          ),
        ],
      ),
    ),
  );
}

class _SpeakerListSheet extends StatefulWidget {
  const _SpeakerListSheet({
    required this.presence,
    required this.room,
    this.onUserTap,
  });

  final List<ChatRoomPresence> presence;
  final VoiceRoomEntity room;
  final void Function(ChatRoomPresence user)? onUserTap;

  @override
  State<_SpeakerListSheet> createState() => _SpeakerListSheetState();
}

class _SpeakerListSheetState extends State<_SpeakerListSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<ChatRoomPresence> _filter(int index) {
    final ownerId = widget.room.ownerId;
    switch (index) {
      case 1:
        return widget.presence
            .where(
              (p) =>
                  (p.seatIndex != null && p.seatIndex! <= 6) ||
                  widget.room.djUserIds.contains(p.id),
            )
            .toList();
      case 2:
        return widget.presence
            .where((p) => p.id != ownerId && (p.seatIndex == null || p.seatIndex! > 6))
            .toList();
      default:
        return widget.presence;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scroll) {
        return VoiceGlass(
          borderRadius: 24,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'Konuşmacı Listesi',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              TabBar(
                controller: _tab,
                tabs: const [
                  Tab(text: 'Tümü'),
                  Tab(text: 'Konuşmacı'),
                  Tab(text: 'Dinleyici'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: List.generate(3, (tabIndex) {
                    final list = _filter(tabIndex);
                    return ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final u = list[i];
                        final isOwner = u.id == widget.room.ownerId;
                        final isMod = widget.room.djUserIds.contains(u.id);
                        return ListTile(
                          leading: VoiceNeonAvatar(
                            url: u.image,
                            size: 44,
                            speaking: u.isSpeaking,
                            showCrown: isOwner,
                          ),
                          title: Text(u.displayName),
                          subtitle: Text(
                            isOwner
                                ? 'Sahip'
                                : isMod
                                    ? 'Yönetici'
                                    : 'Dinleyici',
                          ),
                          trailing: Icon(
                            u.isSpeaking
                                ? Icons.mic_rounded
                                : Icons.mic_off_rounded,
                            color: u.isSpeaking
                                ? AppColors.onlineGreen
                                : AppColors.textMuted,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onUserTap?.call(u);
                          },
                        );
                      },
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: VoiceRoomTokens.neonPurple,
                  ),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EffectsSheet extends StatelessWidget {
  const _EffectsSheet({required this.state, required this.notifier});

  final VoiceRoomUiState state;
  final VoiceRoomUiNotifier notifier;

  @override
  Widget build(BuildContext context) {
    const presets = VoiceEffectPreset.values;
    final labels = {
      VoiceEffectPreset.normal: 'Normal',
      VoiceEffectPreset.studio: 'Stüdyo',
      VoiceEffectPreset.robot: 'Robot',
      VoiceEffectPreset.megaphone: 'Megafon',
      VoiceEffectPreset.angry: 'Kızgın',
      VoiceEffectPreset.deep: 'Derin',
      VoiceEffectPreset.space: 'Uzay',
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, __) => VoiceGlass(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ses Efektleri',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 12),
            ...presets.map(
              (p) => RadioListTile<VoiceEffectPreset>(
                value: p,
                groupValue: state.effect,
                title: Text(labels[p]!),
                secondary: const Icon(Icons.play_circle_outline_rounded),
                onChanged: (_) {
                  notifier.setEffect(p);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${labels[p]} efekti seçildi')),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ses seviyesi ${(state.effectVolume * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Slider(
              value: state.effectVolume,
              onChanged: notifier.setEffectVolume,
              activeColor: VoiceRoomTokens.neonBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestSpeakSheet extends StatelessWidget {
  const _RequestSpeakSheet({
    required this.pending,
    required this.onToggle,
  });

  final bool pending;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: VoiceGlass(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: VoiceRoomTokens.fabGradient,
                boxShadow: VoiceRoomTokens.neonGlow(VoiceRoomTokens.neonPurple),
              ),
              child: const Icon(Icons.front_hand_rounded, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              pending ? 'Söz hakkı bekleniyor' : 'Söz hakkı iste',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              pending
                  ? 'Yönetici onayından sonra mikrofonunuz açılacak.'
                  : 'Konuşmacı koltuğuna geçmek için istek gönderin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.95)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onToggle,
              child: Text(
                pending ? 'İsteği geri çek' : 'Söz hakkı iste',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomSettingsSheet extends StatelessWidget {
  const _RoomSettingsSheet({
    required this.room,
    required this.isOwner,
    required this.perms,
    required this.presence,
    this.onUserTap,
    required this.state,
    required this.notifier,
  });

  final VoiceRoomEntity room;
  final bool isOwner;
  final VoiceRoomPermissions perms;
  final List<ChatRoomPresence> presence;
  final void Function(ChatRoomPresence user)? onUserTap;
  final VoiceRoomUiState state;
  final VoiceRoomUiNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (_, __) => VoiceGlass(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Oda Ayarları',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
            SwitchListTile(
              title: const Text('Dinleyici mesajları'),
              value: state.listenerMessagesEnabled,
              onChanged: (_) => notifier.toggleListenerMessages(),
            ),
            SwitchListTile(
              title: const Text('Hediye animasyonları'),
              value: state.giftAnimationsEnabled,
              onChanged: (_) => notifier.toggleGiftAnimations(),
            ),
            SwitchListTile(
              title: const Text('Arka plan müziği'),
              value: state.backgroundMusicEnabled,
              onChanged: perms.canManageDj
                  ? (_) => notifier.toggleBackgroundMusic()
                  : null,
            ),
            SwitchListTile(
              title: const Text('Otomatik mikrofon'),
              value: state.autoOpenMic,
              onChanged: (_) => notifier.toggleAutoOpenMic(),
            ),
            if (perms.canModerate) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Kullanıcı yönetimi'),
                onTap: () {
                  Navigator.pop(context);
                  showVoiceUserManagementSheet(
                    context,
                    presence: presence,
                    onUserTap: onUserTap,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded),
                title: const Text('Yasaklı listesi'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Oda bilgisini düzenle'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.liveRed,
                  side: const BorderSide(color: AppColors.liveRed),
                ),
                child: const Text('Odayı kapat'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showVoiceUserManagementSheet(
  BuildContext context, {
  required List<ChatRoomPresence> presence,
  void Function(ChatRoomPresence user)? onUserTap,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scroll) => VoiceGlass(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Kullanıcı yönetimi',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: presence.length,
                itemBuilder: (_, i) {
                  final u = presence[i];
                  return ListTile(
                    leading: VoiceNeonAvatar(url: u.image, size: 40),
                    title: Text(u.displayName),
                    subtitle: Text(u.chatRole ?? 'dinleyici'),
                    trailing: IconButton(
                      icon: const Icon(Icons.mic_off_rounded),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${u.displayName} susturuldu')),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onUserTap?.call(u);
                    },
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

class _UserProfileSheet extends StatelessWidget {
  const _UserProfileSheet({required this.user, required this.isOwner});

  final ChatRoomPresence user;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: VoiceGlass(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoiceNeonAvatar(
              url: user.image,
              size: 80,
              speaking: user.isSpeaking,
            ),
            const SizedBox(height: 12),
            Text(
              user.displayName,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            if (user.chatRole != null)
              Text(
                user.chatRole!,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isOwner)
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.mic_off_rounded),
                    tooltip: 'Sustur',
                  ),
                IconButton(
                  onPressed: () => context.push('/user/${user.id}'),
                  icon: const Icon(Icons.person_outline_rounded),
                  tooltip: 'Profil',
                ),
                IconButton(
                  onPressed: () => context.push('/chat/${user.id}'),
                  icon: const Icon(Icons.message_rounded),
                  tooltip: 'Mesaj',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium hediye mağazası — mevcut API ile.
Future<void> showPremiumVoiceGiftShop(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
}) {
  return showVoiceRoomGiftPicker(context, ref, room: room);
}
