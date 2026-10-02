import 'package:flutter/material.dart';
import 'package:canlifal_social/core/design_system/cds_bottom_sheet.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/voice_room_ui_provider.dart';
import '../theme/voice_room_tokens.dart';
import '../widgets/premium/voice_glass.dart';
import '../widgets/premium/voice_neon_avatar.dart';
import '../widgets/voice_room_gift_sheet.dart';
import '../../../admin/presentation/widgets/admin_user_hub_launcher.dart';

Future<void> showVoiceSpeakerListSheet(
  BuildContext context, {
  required List<ChatRoomPresence> presence,
  required VoiceRoomEntity room,
  void Function(ChatRoomPresence user)? onUserTap,
}) {
  return CdsBottomSheet.showTransparent(
    context: context,
    builder: (ctx) => _SpeakerListSheet(
      presence: presence,
      room: room,
      onUserTap: onUserTap,
    ),
  );
}

Future<void> showVoiceEffectsSheet(BuildContext context, WidgetRef ref) {
  return CdsBottomSheet.showTransparent(
    context: context,
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
  required Future<void> Function() onPrimary,
}) {
  return CdsBottomSheet.showTransparent(
    context: context,
    builder: (ctx) => _RequestSpeakSheet(
      pending: pending,
      onPrimary: () async {
        await onPrimary();
        if (ctx.mounted) Navigator.pop(ctx);
      },
    ),
  );
}

Future<void> showVoiceUserProfileSheet(
  BuildContext context, {
  required ChatRoomPresence user,
  VoidCallback? onGift,
  VoidCallback? onMessageInRoom,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _UserProfileSheet(
      user: user,
      onGift: onGift,
      onMessageInRoom: onMessageInRoom,
    ),
  );
}

class _SpeakerListSheet extends ConsumerStatefulWidget {
  const _SpeakerListSheet({
    required this.presence,
    required this.room,
    this.onUserTap,
  });

  final List<ChatRoomPresence> presence;
  final VoiceRoomEntity room;
  final void Function(ChatRoomPresence user)? onUserTap;

  @override
  ConsumerState<_SpeakerListSheet> createState() => _SpeakerListSheetState();
}

class _SpeakerListSheetState extends ConsumerState<_SpeakerListSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  List<ChatRoomPresence> get _allPresence {
    if (widget.presence.isNotEmpty) return widget.presence;
    final ownerId = widget.room.ownerId;
    if (widget.room.ownerName != null) {
      return [
        ChatRoomPresence(
          id: ownerId ?? 'owner',
          name: widget.room.ownerName!,
          image: widget.room.ownerAvatarUrl,
          chatRole: 'owner',
          seatIndex: 1,
        ),
      ];
    }
    return widget.presence;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<ChatRoomPresence> _filter(int index) {
    final ownerId = widget.room.ownerId;
    final list = _allPresence;
    switch (index) {
      case 1:
        return list
            .where(
              (p) =>
                  (p.seatIndex != null && p.seatIndex! <= 6) ||
                  widget.room.djUserIds.contains(p.id) ||
                  p.isSpeaking,
            )
            .toList();
      case 2:
        return list
            .where((p) => p.id != ownerId && (p.seatIndex == null || p.seatIndex! > 6))
            .toList();
      default:
        return list;
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
                'Odada — Katılımcılar',
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
                    if (list.isEmpty) {
                      return ListView(
                        controller: scroll,
                        padding: const EdgeInsets.all(24),
                        children: const [
                          Center(
                            child: Text(
                              'Henüz liste boş — birkaç saniye sonra yenileyin',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final u = list[i];
                        final isOwner = u.id == widget.room.ownerId;
                        final isMod = widget.room.djUserIds.contains(u.id);
                        return AdminUserHubLauncher.wrap(
                          context: context,
                          ref: ref,
                          userId: u.id,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onUserTap?.call(u);
                          },
                          child: ListTile(
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
                                  ? AppThemeColors.onlineGreen
                                  : context.colors.onSurfaceMuted,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onUserTap?.call(u);
                            },
                          ),
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
      builder: (_, _) => VoiceGlass(
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
    required this.onPrimary,
  });

  final bool pending;
  final Future<void> Function() onPrimary;

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
              style: TextStyle(color: context.colors.onSurfaceMuted.withValues(alpha: 0.95)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onPrimary,
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

class _UserProfileSheet extends StatelessWidget {
  const _UserProfileSheet({
    required this.user,
    this.onGift,
    this.onMessageInRoom,
  });

  final ChatRoomPresence user;
  final VoidCallback? onGift;
  final VoidCallback? onMessageInRoom;

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
                style: TextStyle(color: context.colors.onSurfaceMuted),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (onGift != null)
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onGift!();
                    },
                    icon: const Icon(Icons.card_giftcard_rounded),
                    tooltip: 'Hediye gönder',
                    color: AppThemeColors.coinGold,
                  ),
                IconButton(
                  onPressed: () {
                    final id = user.id.trim();
                    if (id.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bu kullanıcı için profil açılamıyor'),
                        ),
                      );
                      return;
                    }
                    context.push('/user/$id');
                  },
                  icon: const Icon(Icons.person_outline_rounded),
                  tooltip: 'Profil',
                ),
                IconButton(
                  onPressed: () {
                    if (onMessageInRoom != null) {
                      Navigator.pop(context);
                      onMessageInRoom!();
                      return;
                    }
                    context.push('/chat/${user.id}');
                  },
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
  List<ChatRoomPresence> seatedUsers = const [],
  ChatRoomPresence? initialReceiver,
  VoidCallback? onGiftSent,
}) {
  return showVoiceRoomGiftPicker(
    context,
    ref,
    room: room,
    seatedUsers: seatedUsers,
    initialReceiver: initialReceiver,
    onGiftSent: onGiftSent,
  );
}
