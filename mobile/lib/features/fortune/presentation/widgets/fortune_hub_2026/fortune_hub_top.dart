import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../../core/economy/presentation/widgets/currency_amount_label.dart';
import '../../../../inbox/presentation/inbox_routes.dart';
import '../../../../inbox/presentation/providers/inbox_unread_providers.dart';
import '../../data/fortune_catalog.dart';
import '../../data/fortune_type_images.dart';
import '../../navigation/fortune_card_navigation.dart';
import '../../providers/fortune_api_providers.dart';
import '../../providers/fortune_hub_providers.dart';
import 'fortune_hub_kit.dart';

/// Üst bar: ☰ · ✨ Fal & Tarot ✨ · bildirim / geçmiş / cüzdan.
class FortuneHubHeader extends StatelessWidget {
  const FortuneHubHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, top + 6, 12, 6),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.menu_rounded,
            semanticLabel: 'Menü',
            onTap: () => showFortuneHubMenu(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: FortuneUi.gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Fal & Tarot',
                        style: FortuneUi.display(
                          22,
                          weight: FontWeight.w700,
                          color: FortuneUi.gold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: FortuneUi.gold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'MİSTİK • KEŞFET • AYDINLAN',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: FortuneUi.lilac.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const _HeaderActions(),
        ],
      ),
    );
  }
}

class _HeaderActions extends ConsumerWidget {
  const _HeaderActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxUnreadCountProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(
          icon: Icons.history_rounded,
          semanticLabel: 'Fal geçmişim',
          onTap: () => context.push('/favorites'),
        ),
        const SizedBox(width: 6),
        _RoundIconButton(
          icon: Icons.notifications_none_rounded,
          semanticLabel: 'Bildirimler ve mesajlar',
          badgeCount: unread,
          onTap: () => InboxRoutes.open(context),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return FortunePressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: FortuneUi.glass(radius: 14, strong: true),
                child: Icon(icon, size: 21, color: Colors.white),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B5C),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FortuneUi.bg1),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// CFC / Jeton bakiyesi — `economyWalletProvider` (gerçek cüzdan).
class FortuneWalletBar extends ConsumerWidget {
  const FortuneWalletBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(economyWalletProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(FortuneUi.padH, 0, FortuneUi.padH, 6),
      child: wallet.when(
        loading: () => const SizedBox(height: 34),
        error: (_, _) => Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () => ref.invalidate(economyWalletProvider),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'Bakiye yüklenemedi — yenile',
                style: FortuneUi.caption,
              ),
            ),
          ),
        ),
        data: (snap) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _WalletPill(
              child: CurrencyAmountLabel(
                amount: snap.cfc,
                currencyKey: 'cfc',
                compact: true,
                showName: false,
              ),
            ),
            const SizedBox(width: 8),
            _WalletPill(
              child: CurrencyAmountLabel(
                amount: snap.jeton,
                currencyKey: 'jeton',
                compact: true,
                showName: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletPill extends StatelessWidget {
  const _WalletPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: FortuneUi.glass(radius: 14),
      child: child,
    );
  }
}

/// Ana hero: "Kaderin Bugün Sana Ne Söylüyor?" + Falına Bak CTA.
class FortuneHubHero extends StatelessWidget {
  const FortuneHubHero({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = MediaQuery.textScalerOf(
      context,
    ).clamp(minScaleFactor: 1, maxScaleFactor: 1.15);
    final titleSize = width < 360 ? 25.0 : 29.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(FortuneUi.padH, 6, FortuneUi.padH, 0),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scale),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FortuneUi.radiusLg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FortuneUi.radiusLg),
              border: Border.all(
                color: FortuneUi.lilac.withValues(alpha: 0.28),
              ),
            ),
            child: Stack(
              children: [
                // Sağda mistik küre görseli (yerel sanat), soldan karartılır.
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.78,
                      heightFactor: 1,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (r) => const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.transparent, Colors.black],
                          stops: [0, 0.55],
                        ).createShader(r),
                        child: const FortuneCover(
                          slug: 'yildiz-haritasi',
                          imageWidth: 720,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x55140630), Color(0xCC0A0420)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.66,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Kaderin\nBugün Sana\nNe Söylüyor?',
                          style: FortuneUi.display(
                            titleSize,
                            weight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.7,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tarot, Kahve ve Astroloji ile geleceğini keşfet.',
                          style: FortuneUi.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FortuneGoldButton(
                        label: 'Falına Bak',
                        icon: Icons.auto_awesome_rounded,
                        onTap: () => context.push(
                          '/fortune/${FortuneCatalog.dailyFortune.slug}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enerjin / Ay Evresi mini kartları — `fortuneDailyInsightsProvider`.
class FortuneHubStatRow extends ConsumerWidget {
  const FortuneHubStatRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(fortuneDailyInsightsProvider);
    final energy = insights.valueOrNull?.energyLabel ?? '—';
    final moon =
        insights.valueOrNull?.moonPhase ?? fortuneMoonPhaseFor(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(FortuneUi.padH, 12, FortuneUi.padH, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.bolt_rounded,
              iconColor: FortuneUi.gold,
              label: 'Enerjin',
              value: energy,
              onTap: () =>
                  context.push('/fortune/${FortuneCatalog.dailyFortune.slug}'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.nightlight_round,
              iconColor: FortuneUi.cyan,
              label: 'Ay Evresi',
              value: moon,
              onTap: () => context.push('/fortune/yildiz-haritasi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FortuneGlassCard(
      onTap: onTap,
      radius: FortuneUi.radiusSm + 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.16),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FortuneUi.caption,
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

/// "N fal kaydın var" bandı — `fortuneHistoryProvider` (gerçek geçmiş).
class FortuneHubHistoryBanner extends ConsumerWidget {
  const FortuneHubHistoryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(fortuneHistoryProvider);
    final items = history.valueOrNull;
    final count = items?.length ?? 0;

    String title;
    String subtitle;
    if (history.isLoading && items == null) {
      title = 'Fal kayıtların yükleniyor…';
      subtitle = 'Bugün yeni bir kehanet keşfet';
    } else if (history.hasError && items == null) {
      title = 'Fal kayıtların şu an alınamadı';
      subtitle = 'Dokunarak geçmişini aç';
    } else if (count == 0) {
      title = 'Henüz fal kaydın yok';
      subtitle = 'İlk falına bak, kehanetini keşfet';
    } else {
      title = '$count fal kaydın var';
      subtitle = 'Bugün yeni bir kehanet keşfet';
    }

    final slugs = <String>[];
    for (final it in items ?? const []) {
      final s = it.slug;
      if (s != null &&
          s.isNotEmpty &&
          FortuneTypeImages.assetPathFor(s) != null &&
          !slugs.contains(s)) {
        slugs.add(s);
      }
      if (slugs.length == 4) break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(FortuneUi.padH, 10, FortuneUi.padH, 0),
      child: FortuneGlassCard(
        onTap: () => context.push('/favorites'),
        strong: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            if (slugs.isNotEmpty)
              SizedBox(
                width: 24.0 + slugs.length * 20,
                height: 36,
                child: Stack(
                  children: [
                    for (var i = 0; i < slugs.length; i++)
                      Positioned(
                        left: i * 20.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: FortuneUi.bg1, width: 2),
                          ),
                          child: ClipOval(
                            child: FortuneCover(slug: slugs[i], imageWidth: 96),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              const Icon(
                Icons.history_rounded,
                color: FortuneUi.lilac,
                size: 30,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FortuneUi.caption,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: FortuneUi.lilac,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Arama alanı — `fortuneHubSearchQueryProvider` ile tür kartlarını süzer.
class FortuneHubSearchField extends ConsumerStatefulWidget {
  const FortuneHubSearchField({super.key});

  @override
  ConsumerState<FortuneHubSearchField> createState() =>
      _FortuneHubSearchFieldState();
}

class _FortuneHubSearchFieldState extends ConsumerState<FortuneHubSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(fortuneHubSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = ref.watch(
      fortuneHubSearchQueryProvider.select((q) => q.isNotEmpty),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(FortuneUi.padH, 12, FortuneUi.padH, 0),
      child: DecoratedBox(
        decoration: FortuneUi.glass(radius: FortuneUi.radius),
        child: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          cursorColor: FortuneUi.gold,
          onChanged: (v) =>
              ref.read(fortuneHubSearchQueryProvider.notifier).state = v,
          decoration: InputDecoration(
            hintText: 'Fal türü ara (tarot, kahve, aşk...)',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: FortuneUi.lilac,
            ),
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: FortuneUi.textMuted,
                    onPressed: () {
                      _controller.clear();
                      ref.read(fortuneHubSearchQueryProvider.notifier).state =
                          '';
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

/// Hub menüsü (☰).
void showFortuneHubMenu(BuildContext context) {
  const items = <({IconData icon, String label, String route})>[
    (
      icon: Icons.grid_view_rounded,
      label: 'Tüm Fal Türleri',
      route: '/fortune/types',
    ),
    (
      icon: Icons.menu_book_rounded,
      label: 'Hazır Yorumlar',
      route: '/fortune/ready',
    ),
    (icon: Icons.history_rounded, label: 'Fal Geçmişim', route: '/favorites'),
    (
      icon: Icons.psychology_rounded,
      label: 'Canlı Falcılar',
      route: '/canli-falcilar',
    ),
    (
      icon: Icons.auto_fix_high_rounded,
      label: 'Bana Özel',
      route: '/fortune/bana-ozel',
    ),
  ];
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: FortuneUi.bg1,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final it in items)
              ListTile(
                leading: Icon(it.icon, color: FortuneUi.lilac),
                title: Text(
                  it.label,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (it.route == '/fortune/types') {
                    openFortuneTypesCatalog(context);
                  } else {
                    context.push(it.route);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: FortuneUi.lilac),
              title: const Text(
                'Ana Sayfa',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/feed');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: FortuneUi.lilac),
              title: const Text(
                'Profil',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/profile');
              },
            ),
          ],
        ),
      ),
    ),
  );
}
