import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/staff_access_provider.dart';

/// Şikayet / içerik moderasyon kuyruğu. Backend `GET/POST /api/admin/moderation`
/// yalnızca web oturumu kabul eder ve genel şikayet listesi ucu yoktur; kuyruk
/// web yönetici panelinde açılır. Kullanıcı bazlı şikayetler kullanıcı 360
/// ekranındaki "Şikayetler" sekmesindedir.
class AdminModerationQueuePage extends ConsumerWidget {
  const AdminModerationQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Center(
          child: access.canModerate
              ? DiscoverEmptyState(
                  icon: Icons.flag_rounded,
                  message:
                      'Gönderi, yorum ve kullanıcı moderasyonu web yönetici '
                      'panelinde yapılır. Bir kullanıcının şikayetlerini '
                      'kullanıcı detayındaki "Şikayetler" sekmesinde görebilirsin.',
                  actionLabel: 'Web panelde aç',
                  action: () => context.push('/admin/web'),
                )
              : DiscoverEmptyState(
                  icon: Icons.lock_outline_rounded,
                  message: 'Moderasyon yetkisi gerekli.',
                  actionLabel: 'Geri',
                  action: () => Navigator.of(context).maybePop(),
                ),
        ),
      ),
    );
  }
}
