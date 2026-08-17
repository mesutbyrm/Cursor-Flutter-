import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../providers/referral_providers.dart';

/// Arkadaşını davet et — backend hesaplı istatistikler, paylaşım.
class ReferralInvitePage extends ConsumerWidget {
  const ReferralInvitePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(referralStatsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Arkadaşını davet et',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/referral/users'),
            child: const Text('Referanslarım'),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ReferralBackdrop(),
          RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () async {
              ref.invalidate(referralStatsProvider);
              await ref.read(referralStatsProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
                    16,
                    24,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: stats.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (e, _) => _ErrorPanel(
                        message: ApiException.userMessage(e),
                        onRetry: () => ref.invalidate(referralStatsProvider),
                      ),
                      data: (s) => _InviteContent(stats: s),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteContent extends StatelessWidget {
  const _InviteContent({required this.stats});

  final dynamic stats;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Panoya kopyalandı')),
      );
    }
  }

  Future<void> _share(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  Future<void> _shareWhatsApp(String text) async {
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(text)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareTelegram(String text) async {
    final uri = Uri.parse(
      'https://t.me/share/url?url=${Uri.encodeComponent(stats.shareUrl)}&text=${Uri.encodeComponent(text)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shareText = [
      if (stats.headline != null && stats.headline!.trim().isNotEmpty)
        stats.headline!.trim(),
      if (stats.rewardHint != null && stats.rewardHint!.trim().isNotEmpty)
        stats.rewardHint!.trim(),
      stats.shareUrl,
    ].join('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlowPanel(
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Davet bağlantın',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
              if (stats.headline != null) ...[
                const SizedBox(height: 10),
                Text(
                  stats.headline!,
                  style: TextStyle(
                    color: AppTheme.muted.withValues(alpha: 0.95),
                    height: 1.35,
                  ),
                ),
              ],
              if (stats.rewardHint != null) ...[
                const SizedBox(height: 8),
                Text(
                  stats.rewardHint!,
                  style: TextStyle(
                    color: AppTheme.accentSecondary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _StatRow(
                label: 'Davet kodu',
                value: stats.referralCode,
              ),
              _StatRow(
                label: 'Getirdiğin kişi',
                value: '${stats.invitedCount}',
              ),
              _StatRow(
                label: 'Aktif referans',
                value: '${stats.activeReferralCount}',
              ),
              _StatRow(
                label: 'Toplam kazanç',
                value: '${stats.totalEarnings} Jeton',
              ),
              const SizedBox(height: 10),
              SelectableText(
                stats.shareUrl,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _share(shareText, subject: 'Canlifal daveti'),
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Paylaş'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _copy(context, stats.shareUrl),
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Bağlantıyı kopyala'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _copy(context, stats.referralCode),
          icon: const Icon(Icons.tag_rounded),
          label: const Text('Kodu kopyala'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _shareWhatsApp(shareText),
          icon: const Icon(Icons.chat_rounded),
          label: const Text('WhatsApp'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _shareTelegram(shareText),
          icon: const Icon(Icons.send_rounded),
          label: const Text('Telegram'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.push('/referral/earnings'),
          child: const Text('Kazançlarım'),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppTheme.muted.withValues(alpha: 0.9)),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlowPanel(
      borderRadius: 18,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
        ],
      ),
    );
  }
}

class _ReferralBackdrop extends StatelessWidget {
  const _ReferralBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.background,
        gradient: LinearGradient(
          colors: [
            const Color(0xFF151028),
            AppTheme.background,
            const Color(0xFF0A1418),
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
