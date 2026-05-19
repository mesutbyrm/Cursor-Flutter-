import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/live_providers.dart';

class LivePage extends ConsumerWidget {
  const LivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı yayınlar'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(liveStreamsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: live.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(ApiException.userMessage(e))),
        data: (streams) {
          if (streams.isEmpty) {
            return const Center(child: Text('Şu an canlı yayın yok'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: streams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final s = streams[i];
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: s.thumbnailUrl != null &&
                              s.thumbnailUrl!.isNotEmpty
                          ? Image.network(
                              s.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const ColoredBox(
                                color: AppTheme.surface,
                                child: Icon(Icons.live_tv_rounded,
                                    color: AppTheme.accent),
                              ),
                            )
                          : const ColoredBox(
                              color: AppTheme.surface,
                              child: Icon(Icons.live_tv_rounded,
                                  color: AppTheme.accent),
                            ),
                    ),
                  ),
                  title: Text(
                    s.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${s.streamerName ?? 'Yayıncı'} · ${s.viewerCount} izleyici',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: s.isLive
                          ? AppTheme.accent.withValues(alpha: 0.2)
                          : AppTheme.muted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.isLive ? 'CANLI' : 'BİTTİ',
                      style: TextStyle(
                        color: s.isLive ? AppTheme.accent : AppTheme.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
