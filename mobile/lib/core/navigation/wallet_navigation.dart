import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

/// Jeton / CFC / cüzdan sayfalarına güvenilir yönlendirme (sesli oda dahil).
void openJetonStore(BuildContext context, {WidgetRef? ref}) {
  _pushWalletRoute(context, '/jeton-store', ref: ref);
}

void openCfcStore(BuildContext context, {WidgetRef? ref}) {
  _pushWalletRoute(context, '/cfc-store', ref: ref);
}

void openWalletCenter(BuildContext context, {WidgetRef? ref}) {
  _pushWalletRoute(context, '/wallet', ref: ref);
}

void openPremiumMembership(BuildContext context, {WidgetRef? ref}) {
  _pushWalletRoute(context, '/premium-membership', ref: ref);
}

void openGrowthHub(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null) return;
  router.push('/profile/growth');
}

/// Sesli oda / müzik / hediye — yetersiz jeton diyaloğu.
Future<void> showInsufficientJetonDialog(
  BuildContext context, {
  required String message,
  WidgetRef? ref,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Yetersiz jeton'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Kapat'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            openGrowthHub(context);
          },
          child: const Text('Görevler'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            openJetonStore(context, ref: ref);
          },
          child: const Text('Jeton Yükle'),
        ),
      ],
    ),
  );
}

void _pushWalletRoute(
  BuildContext context,
  String location, {
  WidgetRef? ref,
}) {
  if (ref != null) {
    final authed = ref.read(authControllerProvider).valueOrNull != null;
    final guest = ref.read(guestModeProvider);
    if (!authed && guest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jeton ve CFC yüklemek için giriş yapın.'),
        ),
      );
      context.push('/login');
      return;
    }
  }

  final router = GoRouter.maybeOf(context);
  if (router == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sayfa açılamadı — uygulamayı yeniden deneyin.')),
    );
    return;
  }
  router.push(location);
}
