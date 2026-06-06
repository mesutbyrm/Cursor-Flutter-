import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/network/api_exception.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/data/datasources/live_remote_datasource.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';

/// canlifal.com — sesli sohbet odası aç (normal 100 / VIP 5000 jeton).
Future<void> showOpenVoiceChatRoomFlow(BuildContext context, WidgetRef ref) async {
  const normalCost = LiveRemoteDataSource.voiceRoomNormalOpenJetonCost;
  const vipCost = LiveRemoteDataSource.voiceRoomVipOpenJetonCost;
  int balance = 0;
  try {
    balance = (await ref.read(walletBalancesProvider.future).timeout(
          const Duration(seconds: 12),
        ))
        .jeton;
  } catch (_) {
    balance = ref.read(walletBalancesProvider).valueOrNull?.jeton ?? 0;
  }

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
              'Normal oda $normalCost jeton · VIP oda $vipCost jeton',
              style: TextStyle(
                color: ctx.colors.onSurfaceMuted.withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bakiyeniz: $balance jeton',
              style: TextStyle(
                color: balance >= normalCost
                    ? AppThemeColors.accentCyan
                    : AppThemeColors.liveRed,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, _OpenRoomChoice.standard),
              icon: const Icon(Icons.mic_rounded),
              label: Text('Sesli oda aç · $normalCost jeton'),
              style: FilledButton.styleFrom(
                backgroundColor: AppThemeColors.accentPurple,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, _OpenRoomChoice.vip),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: Text('VIP oda aç · $vipCost jeton'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppThemeColors.coinGold,
                side: const BorderSide(color: AppThemeColors.coinGold),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
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

  final cost = choice == _OpenRoomChoice.vip ? vipCost : normalCost;
  if (balance > 0 && balance < cost) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Yetersiz jeton ($cost gerekli, $balance mevcut).'),
        action: SnackBarAction(
          label: 'Jeton yükle',
          onPressed: () => openJetonStore(context, ref: ref),
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
      child: CircularProgressIndicator(color: AppThemeColors.accentPink),
    ),
  );

  try {
    final user = ref.read(authControllerProvider).valueOrNull;
    final room = await ref
        .read(liveRepositoryProvider)
        .createVoiceChatRoom(
          vip: vip,
          roomName: user?.display ?? user?.username,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception(
            'Oda açma zaman aşımı. İnternet bağlantınızı kontrol edin.',
          ),
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
            onPressed: () => openJetonStore(context, ref: ref),
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
