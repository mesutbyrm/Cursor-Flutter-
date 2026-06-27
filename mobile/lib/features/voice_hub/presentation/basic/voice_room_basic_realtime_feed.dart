import 'package:flutter/material.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_realtime_event.dart';

/// SSE olay akışı — temel oda ekranı.
class VoiceRoomBasicRealtimeFeed extends StatelessWidget {
  const VoiceRoomBasicRealtimeFeed({
    super.key,
    required this.events,
  });

  final List<VoiceRoomRealtimeEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          'Canlı olaylar burada görünür (giriş, çıkış, mikrofon, moderasyon).',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length.clamp(0, 12),
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final e = events[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconFor(e.kind), size: 16, color: _colorFor(context, e.kind)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                e.message,
                style: const TextStyle(fontSize: 13, height: 1.25),
              ),
            ),
          ],
        );
      },
    );
  }

  static IconData _iconFor(VoiceRoomRealtimeKind kind) {
    return switch (kind) {
      VoiceRoomRealtimeKind.join => Icons.login_rounded,
      VoiceRoomRealtimeKind.leave => Icons.logout_rounded,
      VoiceRoomRealtimeKind.micOn => Icons.mic_rounded,
      VoiceRoomRealtimeKind.micOff => Icons.mic_off_rounded,
      VoiceRoomRealtimeKind.mute => Icons.volume_off_rounded,
      VoiceRoomRealtimeKind.unmute => Icons.volume_up_rounded,
      VoiceRoomRealtimeKind.moderation => Icons.gavel_rounded,
      VoiceRoomRealtimeKind.roomUpdate => Icons.meeting_room_rounded,
      VoiceRoomRealtimeKind.system => Icons.info_outline_rounded,
    };
  }

  static Color _colorFor(BuildContext context, VoiceRoomRealtimeKind kind) {
    final scheme = Theme.of(context).colorScheme;
    return switch (kind) {
      VoiceRoomRealtimeKind.join => Colors.green.shade400,
      VoiceRoomRealtimeKind.leave => scheme.onSurfaceVariant,
      VoiceRoomRealtimeKind.micOn => Colors.lightGreenAccent.shade400,
      VoiceRoomRealtimeKind.micOff => scheme.outline,
      VoiceRoomRealtimeKind.mute => Colors.orange.shade400,
      VoiceRoomRealtimeKind.unmute => Colors.teal.shade300,
      VoiceRoomRealtimeKind.moderation => Colors.red.shade300,
      VoiceRoomRealtimeKind.roomUpdate => scheme.primary,
      VoiceRoomRealtimeKind.system => scheme.secondary,
    };
  }
}

/// Katılımcı şeridi — mikrofon (isSpeaking) göstergeli.
class VoiceRoomBasicParticipantStrip extends StatelessWidget {
  const VoiceRoomBasicParticipantStrip({
    super.key,
    required this.presence,
    required this.ownerId,
    this.onUserTap,
  });

  final List<ChatRoomPresence> presence;
  final String? ownerId;
  final void Function(ChatRoomPresence user)? onUserTap;

  @override
  Widget build(BuildContext context) {
    if (presence.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = [...presence];
    sorted.sort((a, b) {
      if (ownerId != null && a.id == ownerId) return -1;
      if (ownerId != null && b.id == ownerId) return 1;
      if (a.isSpeaking != b.isSpeaking) {
        return a.isSpeaking ? -1 : 1;
      }
      return a.displayName.compareTo(b.displayName);
    });

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sorted.length.clamp(0, 24),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final p = sorted[index];
          final isOwner = ownerId != null && p.id == ownerId;
          return GestureDetector(
            onTap: onUserTap == null ? null : () => onUserTap!(p),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: p.image != null && p.image!.isNotEmpty
                        ? canlifalImageProvider(p.image!)
                        : null,
                    child: p.image == null || p.image!.isEmpty
                        ? Text(
                            p.displayName.isNotEmpty
                                ? p.displayName.characters.first.toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  if (p.isSpeaking)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, size: 12, color: Colors.white),
                      ),
                    ),
                  if (isOwner)
                    const Positioned(
                      top: -4,
                      right: -4,
                      child: Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 56,
                child: Text(
                  p.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          );
        },
      ),
    );
  }
}
