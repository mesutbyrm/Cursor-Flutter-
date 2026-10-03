import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../admin/presentation/providers/admin_dashboard_providers.dart';
import '../../../../admin/presentation/providers/admin_providers.dart';
import '../../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../../live/presentation/providers/live_streams_list_notifier.dart';
import '../../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../profile_theme.dart';

/// Admin profili özeti: ADMIN rozeti + yetki seviyesi + gerçek sayaçlar.
///
/// Sayılar mevcut sağlayıcılardan gelir (bekleyen ödeme, aktif yayın/oda,
/// yönetici işlem kaydı); veri yoksa «—» gösterilir, sahte değer üretilmez.
/// Normal kullanıcıda hiç çizilmez.
class AdminProfileSummaryCard extends ConsumerWidget {
  const AdminProfileSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canAccessAdminHome) return const SizedBox.shrink();

    final pending = ref.watch(adminPendingPaymentsCountProvider);
    final rooms = ref.watch(voiceRoomsListNotifierProvider).valueOrNull?.length;
    final streams = ref
        .watch(liveStreamsListNotifierProvider)
        .valueOrNull
        ?.where((s) => s.isLive)
        .length;
    final acts = ref.watch(staffFilteredActivitiesProvider).valueOrNull;

    String fmt(int? v) => v == null || v == 0 ? '—' : '$v';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFC13B).withValues(alpha: 0.16),
            const Color(0xFF7C5CFF).withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(color: const Color(0xFFFFC13B).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD36B), Color(0xFFFF9F1C)],
                  ),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Color(0xFF2B1B00),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                'Yetki seviyesi: ${access.roleLabel}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: ProfilePremiumTheme.textOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 420 ? 4 : 2;
              const gap = 8.0;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              Widget tile(String label, String value) => SizedBox(
                    width: w,
                    child: _Kpi(label: label, value: value),
                  );
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  tile('Yönetici işlemi', fmt(acts?.length)),
                  tile('Bekleyen ödeme', fmt(pending)),
                  tile('Aktif yayın', fmt(streams)),
                  tile('Aktif oda', fmt(rooms)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: ProfilePremiumTheme.insetOf(context, darkAlpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: ProfilePremiumTheme.textOf(context),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: ProfilePremiumTheme.textMutedOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
