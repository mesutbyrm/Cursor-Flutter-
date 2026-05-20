import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../providers/profile_providers.dart';

/// `/api/referral` ile davet bilgisini alır; paylaşım tablosu ve web yedeği.
class InviteFriendsPage extends ConsumerWidget {
  const InviteFriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(referralInfoProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Arkadaşlarını davet et',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _InviteBackdrop(),
          RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () async {
              ref.invalidate(referralInfoProvider);
              await ref.read(referralInfoProvider.future);
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
                    child: info.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (e, _) => GlowPanel(
                        borderRadius: 18,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(Icons.link_off_rounded,
                                size: 44,
                                color: AppTheme.muted.withValues(alpha: 0.9)),
                            const SizedBox(height: 12),
                            Text(
                              ApiException.userMessage(e),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () =>
                                  ref.invalidate(referralInfoProvider),
                              child: const Text('Tekrar dene'),
                            ),
                          ],
                        ),
                      ),
                      data: (r) => _InviteBody(
                        shareUrl: r.shareUrl,
                        headline: r.headline,
                        code: r.code,
                        invitedCount: r.invitedCount,
                        rewardHint: r.rewardHint,
                        onShare: () async {
                          final text = [
                            if (r.headline != null &&
                                r.headline!.trim().isNotEmpty)
                              r.headline!.trim(),
                            r.shareUrl,
                          ].join('\n\n');
                          await SharePlus.instance.share(
                            ShareParams(
                              text: text,
                              subject: 'Canlifal daveti',
                            ),
                          );
                        },
                        onCopy: () async {
                          await Clipboard.setData(
                            ClipboardData(text: r.shareUrl),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bağlantı panoya kopyalandı'),
                              ),
                            );
                          }
                        },
                        onOpenWeb: () => context.push(
                          CanlifalWebRoute.location(
                            relativePath: '/davet',
                            title: 'Davet',
                          ),
                        ),
                      ),
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

class _InviteBody extends StatelessWidget {
  const _InviteBody({
    required this.shareUrl,
    required this.onShare,
    required this.onCopy,
    required this.onOpenWeb,
    this.headline,
    this.code,
    this.invitedCount,
    this.rewardHint,
  });

  final String shareUrl;
  final String? headline;
  final String? code;
  final int? invitedCount;
  final String? rewardHint;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onOpenWeb;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlowPanel(
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.celebration_rounded,
                      color: AppTheme.accent.withValues(alpha: 0.95)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Davet bağlantın',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              if (headline != null && headline!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  headline!,
                  style: TextStyle(
                    color: AppTheme.muted.withValues(alpha: 0.95),
                    height: 1.35,
                  ),
                ),
              ],
              if (rewardHint != null && rewardHint!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  rewardHint!,
                  style: TextStyle(
                    color: AppTheme.accentSecondary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (invitedCount != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Toplam davet: $invitedCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
              if (code != null && code!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Kod: ${code!.trim()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.muted.withValues(alpha: 0.95),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SelectableText(
                shareUrl,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Davet linkini paylaş'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Bağlantıyı kopyala'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onOpenWeb,
          icon: const Icon(Icons.open_in_browser_rounded),
          label: const Text('Web’de davet sayfasını aç'),
        ),
      ],
    );
  }
}

class _InviteBackdrop extends StatelessWidget {
  const _InviteBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.background,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF151028),
            AppTheme.background,
            const Color(0xFF0A1418),
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.75, -0.25),
            radius: 1.0,
            colors: [
              AppTheme.accent.withValues(alpha: 0.14),
              Colors.transparent,
            ],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
