import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../../pages/voice_room_owner_manage_page.dart';
import '../../utils/open_voice_chat_room_flow.dart';
import 'voice_rooms_2026.dart';
import 'voice_rooms_ui_tokens.dart';

/// Odalarım — kullanıcının sahip olduğu odalar (ana ekran özeti).
class MyRoomCard extends ConsumerWidget {
  const MyRoomCard({super.key, this.maxRows = 2});

  /// Ana ekranda en çok kaç oda satırı gösterilsin (0 = hepsi).
  final int maxRows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(myOwnedVoiceRoomsProvider);
    final hasRooms = owned.isNotEmpty;
    final shown = maxRows > 0 ? owned.take(maxRows).toList() : owned;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1252), Color(0xFF170B30)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: VoiceRoomsUiTokens.fabGradient,
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Odalarım',
                      style: TextStyle(
                        color: VoiceRoomsUiTokens.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      hasRooms
                          ? '${owned.length} açık oda'
                          : 'Kendi odanı oluştur',
                      style: const TextStyle(
                        color: VoiceRoomsUiTokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasRooms)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push('/voice-rooms/mine'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tümü',
                          style: TextStyle(
                            color: VoiceRoomsUiTokens.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: VoiceRoomsUiTokens.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (hasRooms) ...[
            const SizedBox(height: 12),
            for (final room in shown) OwnedRoomRow(room: room),
          ],
          const SizedBox(height: 4),
          VrPressable(
            semanticLabel: hasRooms ? 'Yeni oda aç' : 'Oda oluştur',
            onTap: () => showOpenVoiceChatRoomFlow(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: VoiceRoomsUiTokens.purpleGradient,
                borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusPill),
                boxShadow: [
                  BoxShadow(
                    color: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    hasRooms ? 'Yeni Oda Aç' : 'Oda Oluştur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sahip olunan oda satırı: avatar · ad · kategori · dinleyici · ayarlar · ›
class OwnedRoomRow extends ConsumerWidget {
  const OwnedRoomRow({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = (room.ownerAvatarUrl ?? room.backgroundImageUrl)?.trim();
    final online = room.displayOnline;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => openVoiceRoomWithVipGate(
            context,
            ref,
            room,
            skipVipGateForOwner: true,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VoiceRoomsUiTokens.purpleEnd,
                    border: Border.all(
                      color: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: image != null && image.isNotEmpty
                      ? CanlifalNetworkImage(
                          url: image,
                          width: 44,
                          height: 44,
                          thumbnailWidth: 96,
                          fadeIn: false,
                          errorWidget: _initial(),
                        )
                      : _initial(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        room.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: VoiceRoomsUiTokens.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: VoiceRoomCategoryChip(category: room.category),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: online > 0
                          ? VoiceRoomsUiTokens.onlineGreen
                          : VoiceRoomsUiTokens.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$online',
                      style: TextStyle(
                        color: online > 0
                            ? VoiceRoomsUiTokens.onlineGreen
                            : VoiceRoomsUiTokens.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Oda ayarları',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => openVoiceRoomOwnerManagePage(context, room),
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: VoiceRoomsUiTokens.textPrimary,
                    size: 21,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: VoiceRoomsUiTokens.textSecondary,
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _initial() => Text(
        room.displayTitle.characters.first.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      );
}
