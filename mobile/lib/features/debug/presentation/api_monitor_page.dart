import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_backend_router.dart';
import '../../../core/network/api_monitor.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../feed/presentation/widgets/discover/discover_background.dart';
import '../../profile/presentation/widgets/premium/profile_glass.dart';

/// Debug — son HTTP istekleri (Backend-2 uyumu: URL, backend, süre, retry).
class ApiMonitorPage extends ConsumerStatefulWidget {
  const ApiMonitorPage({super.key});

  @override
  ConsumerState<ApiMonitorPage> createState() => _ApiMonitorPageState();
}

class _ApiMonitorPageState extends ConsumerState<ApiMonitorPage> {
  @override
  void initState() {
    super.initState();
    ApiMonitor.addListener(_onUpdate);
  }

  @override
  void dispose() {
    ApiMonitor.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entries = ApiMonitor.entries;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'API Monitor',
          subtitle: 'Debug — son ${entries.length} istek',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileGlass(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend yönlendirme',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(label: 'Main', value: Env.apiBaseUrl),
                    _InfoRow(label: 'Game', value: Env.gamesApiBaseUrl),
                    if (ApiBackendRouter.hasGatewayFallback)
                      _InfoRow(
                        label: 'Gateway (yedek)',
                        value: Env.gatewayApiBaseUrl,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Split: ${ApiBackendRouter.usesSplitBackends ? "aktif" : "kapalı"}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.onSurfaceMuted,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: ApiMonitor.clear,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Temizle'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          'Henüz istek yok.\nUygulamada gezinince burada görünür.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: context.colors.onSurfaceMuted,
                              ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final e = entries[index];
                          return _EntryTile(entry: e);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final ApiMonitorEntry entry;

  Color _statusColor(BuildContext context) {
    if (entry.statusCode == null) return Colors.orange;
    if (entry.isSuccess) return Colors.green;
    if (entry.statusCode! >= 500) return Colors.red;
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.statusCode?.toString() ?? 'ERR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _statusColor(context),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.method,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(entry.backend, style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              if (entry.usedGatewayFallback)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Chip(
                    label: Text('GW', style: TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              const Spacer(),
              Text(
                '${entry.responseTimeMs}ms',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.url,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
          if (entry.retryCount > 0)
            Text(
              'Retry: ${entry.retryCount}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.orange,
                  ),
            ),
          if (entry.error != null)
            Text(
              entry.error!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
        ],
      ),
    );
  }
}
