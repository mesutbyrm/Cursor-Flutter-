import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../live/data/datasources/live_remote_datasource.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';

/// canlifal.com — sesli sohbet odası aç (100 jeton); Gold+ VIP oda seçeneği.
Future<void> showOpenVoiceChatRoomFlow(BuildContext context, WidgetRef ref) async {
  final tier = ref.read(vipTierProvider);
  final canVip = canEnterVipRoom(tier);
  final balance = ref.read(walletBalancesProvider).valueOrNull?.jeton ?? 0;
  const cost = LiveRemoteDataSource.voiceRoomOpenJetonCost;

  final choice = await showModalBottomSheet<_OpenRoomChoice>(
    context: context,
    backgroundColor: const Color(0xFF12081F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sesli Sohbet Odası Aç',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'canlifal.com ile aynı: $cost jeton karşılığında kendi odanızı açın.',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bakiyeniz: $balance jeton',
              style: TextStyle(
                color: balance >= cost
                    ? AppColors.accentCyan
                    : AppColors.liveRed,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, _OpenRoomChoice.standard),
              icon: const Icon(Icons.mic_rounded),
              label: Text('Sesli oda aç · $cost jeton'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (canVip) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx, _OpenRoomChoice.vip),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text('VIP oda aç · $cost jeton'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coinGold,
                  side: const BorderSide(color: AppColors.coinGold),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                'VIP oda açmak için Gold üyelik gerekir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted.withValues(alpha: 0.85),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
          ],
        ),
      ),
    ),
  );

  if (choice == null || !context.mounted) return;

  if (balance < cost) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Yetersiz jeton ($cost gerekli, $balance mevcut).'),
        action: SnackBarAction(
          label: 'Jeton yükle',
          onPressed: () => context.push('/jeton-store'),
        ),
      ),
    );
    return;
  }

  await _createAndEnter(context, ref, vip: choice == _OpenRoomChoice.vip);
}

enum _OpenRoomChoice { standard, vip }

Future<void> _createAndEnter(
  BuildContext context,
  WidgetRef ref, {
  required bool vip,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: AppColors.accentPink),
    ),
  );

  try {
    final room = await ref.read(liveRepositoryProvider).createVoiceChatRoom(
          vip: vip,
        );
    ref.invalidate(voiceRoomsProvider);
    ref.invalidate(walletBalancesProvider);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vip ? 'VIP sesli oda açıldı' : 'Sesli sohbet odanız açıldı',
        ),
      ),
    );
    await openVoiceRoomWithVipGate(context, ref, room);
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    final msg = ApiException.userMessage(e);
    if (msg.toLowerCase().contains('yetersiz') ||
        msg.toLowerCase().contains('jeton')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          action: SnackBarAction(
            label: 'Jeton yükle',
            onPressed: () => context.push('/jeton-store'),
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
