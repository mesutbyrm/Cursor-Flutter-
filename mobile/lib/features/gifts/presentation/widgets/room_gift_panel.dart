import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../live/domain/entities/live_gift_catalog.dart';
import '../../../live/domain/entities/live_gift_type.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../voice_hub/presentation/widgets/voice_room_gift_sheet.dart';

/// Ses odası hediyeleri — web’e gitmeden uygulama içi gönderim.
class RoomGiftPanel extends ConsumerWidget {
  const RoomGiftPanel({
    super.key,
    required this.roomId,
    this.receiverName = 'Oda sahibi',
    this.onSent,
  });

  final String roomId;
  final String receiverName;
  final VoidCallback? onSent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gifts = ref.watch(voiceRoomGiftTypesProvider);

    return gifts.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          ApiException.userMessage(e),
          textAlign: TextAlign.center,
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(child: Text('Hediye listesi boş'));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Hediye gönder · $receiverName',
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
            SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final g = list[i];
                  return _RoomGiftTile(
                    gift: g,
                    onTap: () => _send(context, ref, g),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _send(
    BuildContext context,
    WidgetRef ref,
    LiveVideoGiftType g,
  ) async {
    try {
      await ref.read(chatRoomGiftsRemoteProvider).sendGift(
            roomId: roomId,
            giftTypeId: g.id,
          );
      if (!context.mounted) return;
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      onSent?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LiveGiftCatalog.displayName(g)} gönderildi'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }
}

class _RoomGiftTile extends StatelessWidget {
  const _RoomGiftTile({required this.gift, required this.onTap});

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
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (url.isNotEmpty)
                CachedNetworkImage(imageUrl: url, height: 40, width: 40)
              else
                Icon(Icons.card_giftcard_rounded, size: 32),
              SizedBox(height: 6),
              Text(
                LiveGiftCatalog.displayName(gift),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              Text(
                '${gift.price} jeton',
                style: TextStyle(
                  fontSize: 10,
                  color: AppThemeColors.accentPink.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
