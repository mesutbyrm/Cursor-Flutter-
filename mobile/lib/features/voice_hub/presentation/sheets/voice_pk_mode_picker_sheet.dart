import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../gifts/presentation/providers/gift_battle_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../pk/presentation/providers/pk_feature_enabled_provider.dart';
import '../../../pk/presentation/providers/pk_session_notifier.dart';
import '../../../pk/presentation/widgets/pk_start_sheet.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../theme/voice_room_tokens.dart';
import 'voice_in_room_pk_sheet.dart';

enum VoicePkMode { roomPk, giftBattle, inRoomTeam }

/// PK — odalar arası, hediye savaşı veya oda içi takım PK.
Future<VoicePkMode?> showVoicePkModePicker(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required List<ChatRoomPresence> presence,
  required bool isOwner,
  VoidCallback? onGiftBattle,
}) {
  if (!ref.read(pkFeatureEnabledProvider)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PK şu an kapalı')),
    );
    return Future.value(null);
  }
  return showModalBottomSheet<VoicePkMode>(
    context: context,
    backgroundColor: const Color(0xFF12082A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 14),
            const Text(
              'PK türü seçin',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 16),
            _PkModeTile(
              icon: Icons.sports_mma_rounded,
              title: 'Odalarla PK',
              subtitle: 'Başka bir odayı PK\'ya davet et',
              accent: VoiceRoomTokens.neonPink,
              onTap: () => Navigator.pop(ctx, VoicePkMode.roomPk),
            ),
            const SizedBox(height: 10),
            _PkModeTile(
              icon: Icons.local_fire_department_rounded,
              title: 'Hediye savaşı',
              subtitle: 'Koltuktakiler jeton hediyeleriyle yarışır',
              accent: const Color(0xFFFF7043),
              onTap: () => Navigator.pop(ctx, VoicePkMode.giftBattle),
            ),
            if (isOwner) ...[
              const SizedBox(height: 10),
              _PkModeTile(
                icon: Icons.groups_rounded,
                title: 'Oda içi PK (takım)',
                subtitle: 'Odadaki kullanıcılarla 2 takım, en fazla 4+4',
                accent: VoiceRoomTokens.neonPurple,
                onTap: () => Navigator.pop(ctx, VoicePkMode.inRoomTeam),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<void> launchVoiceGiftBattle(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required List<ChatRoomPresence> presence,
}) async {
  final present = presence.where((p) => p.id.isNotEmpty).toList();
  final seatedUsers = present.where((p) => p.seatIndex != null).toList();
  final seated = seatedUsers.length >= 2 ? seatedUsers : present;
  if (seated.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Savaş için odada en az 2 kişi olmalı')),
    );
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
            child: Text(
              'Savaş süresi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
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
  if (duration == null || !context.mounted) return;
  try {
    final contextId =
        room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    final battle = await ref.read(giftBattleRemoteProvider).startBattle(
          context: 'voice_room',
          contextId: contextId,
          durationSec: duration,
          participants: [
            for (final p in seated) (id: p.id, name: p.displayName),
          ],
        );
    if (battle != null) {
      ref
          .read(giftBattleProvider(
                  (context: 'voice_room', contextId: contextId))
              .notifier)
          .adopt(battle);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hediye savaşı başladı!')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}

Future<void> runVoicePkModeSelection(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required List<ChatRoomPresence> presence,
  required bool isOwner,
  required Future<void> Function() onGiftBattle,
}) async {
  final pk = ref.read(pkBattleForRoomProvider(room));
  if (isPkBattleLive(pk)) {
    final roomKey =
        room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (context.mounted) {
      context.push('/voice-room/$roomKey/pk', extra: room);
    }
    return;
  }
  final mode = await showVoicePkModePicker(
    context,
    ref,
    room: room,
    presence: presence,
    isOwner: isOwner,
  );
  if (!context.mounted || mode == null) return;
  switch (mode) {
    case VoicePkMode.roomPk:
      final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
      if (key.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oda bilgisi yüklenemedi — PK başlatılamadı'),
          ),
        );
        return;
      }
      await showPkStartSheet(
        context,
        ref,
        args: PkSessionArgs(contextId: key, kind: PkContextKind.voice),
      );
    case VoicePkMode.giftBattle:
      await onGiftBattle();
    case VoicePkMode.inRoomTeam:
      await showVoiceInRoomPkSheet(
        context,
        ref,
        room: room,
        presence: presence,
      );
  }
}

class _PkModeTile extends StatelessWidget {
  const _PkModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
