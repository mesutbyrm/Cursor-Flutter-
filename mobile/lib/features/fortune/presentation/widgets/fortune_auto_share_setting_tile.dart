import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fortune_share_preferences.dart';
import '../providers/fortune_share_preferences_provider.dart';

/// Ayarlar — otomatik fal paylaşım modu.
class FortuneAutoShareSettingTile extends ConsumerWidget {
  const FortuneAutoShareSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeAsync = ref.watch(fortuneAutoShareModeProvider);

    return modeAsync.when(
      loading: () => const ListTile(
        title: Text('Fal Sonuçlarımı Otomatik Paylaş'),
        subtitle: Text('Yükleniyor…'),
      ),
      error: (_, _) => const ListTile(
        title: Text('Fal Sonuçlarımı Otomatik Paylaş'),
        subtitle: Text('Tercih okunamadı'),
      ),
      data: (mode) => ListTile(
        leading: const Icon(Icons.auto_awesome_outlined),
        title: const Text('Fal Sonuçlarımı Otomatik Paylaş'),
        subtitle: Text(
          mode == FortuneAutoShareMode.off
              ? 'Kapalı — backend paylaşımı gösterilmez'
              : '${mode.label} — sunucu otomatik paylaşır, uygulama senkronize eder',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _pickMode(context, ref, mode),
      ),
    );
  }

  Future<void> _pickMode(
    BuildContext context,
    WidgetRef ref,
    FortuneAutoShareMode current,
  ) async {
    final picked = await showModalBottomSheet<FortuneAutoShareMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Paylaşımı sunucu oluşturur. Bu ayar yalnızca sosyal akışta '
                'gösterilip gösterilmeyeceğini belirler.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Fal Sonuçlarımı Otomatik Paylaş',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            for (final mode in FortuneAutoShareMode.values)
              RadioListTile<FortuneAutoShareMode>(
                value: mode,
                groupValue: current,
                title: Text(mode.label),
                onChanged: (v) => Navigator.pop(ctx, v),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (picked == null || picked == current) return;
    final prefs = await ref.read(fortuneSharePreferencesProvider.future);
    await prefs.setAutoShareMode(picked);
    ref.invalidate(fortuneAutoShareModeProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Otomatik paylaşım: ${picked.label}')),
      );
    }
  }
}
