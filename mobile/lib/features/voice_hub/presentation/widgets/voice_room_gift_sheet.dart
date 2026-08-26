import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/config/env.dart';
import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gifts/presentation/providers/gift_providers.dart';
import '../../../gifts/domain/premium_gift_catalog_2026.dart';
import '../../../live/domain/entities/live_gift_catalog.dart';
import '../../../live/domain/entities/live_gift_type.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_gift_providers.dart';
import 'premium_2026/voice_premium_gift_panel_2026.dart';

final voiceRoomGiftTypesProvider = FutureProvider.autoDispose((ref) async {
  final catalog = await ref.watch(voiceRoomGiftCatalogProvider.future);
  return catalog.map(LiveVideoGiftType.fromGift).toList();
});

Future<void> showVoiceRoomGiftPicker(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  List<ChatRoomPresence> seatedUsers = const [],
  ChatRoomPresence? initialReceiver,
  VoidCallback? onGiftSent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          return VoicePremiumGiftPanel2026(
            room: room,
            seatedUsers: seatedUsers,
            initialReceiver: initialReceiver,
            onClose: () => Navigator.pop(context),
            onSent: () {
              onGiftSent?.call();
            },
          );
        },
      );
    },
  );
}

/// Eski grid picker — yedek / dar ekran.
Future<void> showVoiceRoomGiftPickerLegacy(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
}) async {
  final receiver = room.ownerName?.trim().isNotEmpty == true
      ? room.ownerName!.trim()
      : 'Oda sahibi';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final gifts = ref.watch(voiceRoomGiftTypesProvider);
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder: (context, scroll) {
              return gifts.when(
                loading: () => Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ApiException.userMessage(e)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(voiceRoomGiftTypesProvider),
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Hediye listesi boş'),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          'Hediye gönder · $receiver',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Jeton bakiyenizden düşülür. Oda sohbetinde herkese görünür.',
                          style: TextStyle(color: context.colors.onSurfaceMuted, fontSize: 12),
                        ),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: GridView.builder(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final g = list[i];
                            return _GiftTile(
                              gift: g,
                              onTap: () async {
                                try {
                                  final user = ref
                                      .read(authControllerProvider)
                                      .valueOrNull;
                                  final roomKey = room.apiRoomKey.isNotEmpty
                                      ? room.apiRoomKey
                                      : room.id;
                                  await ref.read(chatRoomGiftsRemoteProvider).sendGift(
                                        roomId: roomKey,
                                        giftTypeId: g.id,
                                        senderName: user?.display ?? 'Sen',
                                        receiverName:
                                            room.ownerName ?? 'Yayıncı',
                                        receiverId: room.ownerId,
                                      );
                                  await ref
                                      .read(giftSoundServiceProvider)
                                      .playFor(g.toEntity());
                                  if (context.mounted) {
                                    ref.refreshWalletCache(force: true);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${LiveGiftCatalog.displayName(g)} gönderildi',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    showJetonAwareError(
                                      context,
                                      ApiException.userMessage(e),
                                      ref: ref,
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    },
  );
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({required this.gift, required this.onTap});

  final LiveVideoGiftType gift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = gift.iconUrl(Env.siteOrigin);

    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (url.isNotEmpty)
                CanlifalNetworkImage(url: url, height: 36, width: 36)
              else
                Icon(Icons.card_giftcard_rounded, size: 32),
              SizedBox(height: 6),
              Text(
                PremiumGiftCatalog2026.displayName(
                  gift.id,
                  fallback: LiveGiftCatalog.displayName(gift),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              Text(
                '${gift.price} jeton',
                style: TextStyle(fontSize: 10, color: context.colors.onSurfaceMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
