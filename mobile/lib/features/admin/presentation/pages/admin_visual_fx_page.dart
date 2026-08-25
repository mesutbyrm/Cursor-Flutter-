import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../vip_gold/domain/entrance_theme.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/providers/entrance_effect_settings_provider.dart';
import '../../../vip_gold/presentation/widgets/vip_entrance_overlay.dart';
import '../../../visual_fx/domain/fx_gift_tier.dart';
import '../providers/staff_access_provider.dart';

/// Admin — merkezi görsel efekt yönetimi hub'ı.
class AdminVisualFxPage extends ConsumerStatefulWidget {
  const AdminVisualFxPage({super.key});

  @override
  ConsumerState<AdminVisualFxPage> createState() => _AdminVisualFxPageState();
}

class _AdminVisualFxPageState extends ConsumerState<AdminVisualFxPage> {
  var _previewTier = VipTier.gold;
  var _previewGiftTier = FxGiftTier.special;
  var _showPreview = false;

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageGifts) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Görsel efekt yönetimi yalnızca admin içindir.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final entrance = ref.watch(entranceEffectSettingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                SizedBox(height: MediaQuery.paddingOf(context).top + 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 12),
                  child: Row(
                    children: [
                      DiscoverIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Expanded(
                        child: DiscoverTabHeader(
                          title: 'Görsel efektler',
                          subtitle: 'Rozet, giriş, hediye, duyuru',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      _SectionTitle('Bölümler'),
                      _NavTile(
                        icon: Icons.login_rounded,
                        title: 'Giriş efektleri',
                        subtitle: 'Gold / Premium / Diamond hız ve süre',
                        onTap: () => context.push('/admin/entrance-effects'),
                      ),
                      _NavTile(
                        icon: Icons.card_giftcard_rounded,
                        title: 'Hediye yönetimi',
                        subtitle: 'Türler, görseller, değer aralıkları',
                        onTap: () => context.push('/admin/gifts'),
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle('Önizleme'),
                      _PreviewChip(
                        label: 'Üyelik girişi',
                        value: _previewTier.label,
                        onTap: () => setState(() {
                          _previewTier = switch (_previewTier) {
                            VipTier.gold => VipTier.premium,
                            VipTier.premium => VipTier.diamond,
                            _ => VipTier.gold,
                          };
                        }),
                      ),
                      _PreviewChip(
                        label: 'Büyük hediye eşiği',
                        value: '${FxGiftTier.defaultBigGiftThreshold}+ jeton',
                        onTap: () => setState(() {
                          _previewGiftTier = switch (_previewGiftTier) {
                            FxGiftTier.small => FxGiftTier.medium,
                            FxGiftTier.medium => FxGiftTier.special,
                            FxGiftTier.special => FxGiftTier.legendary,
                            _ => FxGiftTier.small,
                          };
                        }),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => setState(() => _showPreview = true),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Önizle'),
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle('Aktif ayarlar'),
                      _InfoRow('Giriş hızı', '${entrance.speed.toStringAsFixed(1)}×'),
                      _InfoRow('Giriş süresi', '${entrance.durationMs} ms'),
                      _InfoRow('Büyük hediye', '${FxGiftTier.defaultBigGiftThreshold}+ jeton üst banner'),
                      _InfoRow('Son hediyeler', '3 sn rotasyon, max 3'),
                      _InfoRow('Duyurular', 'GET /api/popups — sesli oda sağ üst'),
                    ],
                  ),
                ),
              ],
            ),
            if (_showPreview)
              VipEntranceOverlay(
                tier: _previewTier,
                userName: access.username ?? 'Admin',
                theme: EntranceTheme.turkey,
                onFinished: () {
                  if (mounted) setState(() => _showPreview = false);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppThemeColors.accentPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text(value, style: const TextStyle(color: AppThemeColors.accentPurple)),
              const SizedBox(width: 4),
              const Icon(Icons.swap_horiz_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
