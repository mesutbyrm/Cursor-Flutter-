import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import '../widgets/live_fortune_invite_sheet.dart';

class LiveFortuneTellerDetailPage extends ConsumerStatefulWidget {
  const LiveFortuneTellerDetailPage({super.key, required this.tellerId});

  final String tellerId;

  @override
  ConsumerState<LiveFortuneTellerDetailPage> createState() =>
      _LiveFortuneTellerDetailPageState();
}

class _LiveFortuneTellerDetailPageState
    extends ConsumerState<LiveFortuneTellerDetailPage> {
  var _selectedMinutes = 10;
  var _booking = false;

  Future<void> _startSession(LiveFortuneTellerEntity teller) async {
    if (_booking) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Randevu için giriş yapın')),
      );
      return;
    }
    final options = FortuneSessionDurationOption.forTeller(teller);
    final opt = options.firstWhere(
      (o) => o.minutes == _selectedMinutes,
      orElse: () => options[1],
    );
    final balance = ref.read(coinBalanceProvider).valueOrNull ?? user.coinBalance;
    if (balance < opt.totalJeton) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yetersiz jeton. Gerekli: ${opt.totalJeton}, bakiye: $balance',
          ),
        ),
      );
      return;
    }

    final invite = await showLiveFortuneInviteSheet(
      context,
      teller: teller,
      durationMinutes: opt.minutes,
      totalJeton: opt.totalJeton,
    );
    if (!mounted || invite != true) return;

    setState(() => _booking = true);
    try {
      final remote = ref.read(homeRemoteProvider);
      final created = await remote.createFortuneTellerSession(
        teller.id,
        tellerUserId: teller.trtcUserId,
      );
      if (!mounted) return;
      if (created == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oturum başlatılamadı')),
        );
        return;
      }
      final session = LiveFortuneSessionEntity(
        sessionId: created.sessionId,
        teller: teller,
        durationMinutes: opt.minutes,
        totalJeton: opt.totalJeton,
        tellerUserId: created.tellerUserId ?? teller.trtcUserId,
        clientId: created.clientId,
        isClient: created.isClient,
      );
      ref.read(videoWebrtcSignalServiceProvider).start(
            streamId: session.sessionId,
          );
      if (!mounted) return;
      await context.push(
        '/canli-falcilar/${teller.id}/session',
        extra: session,
      );
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tellerAsync = ref.watch(liveFortuneTellerProvider(widget.tellerId));
    final balance = ref.watch(coinBalanceProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: HomePalette.darkBackground,
      body: CosmicGalaxyBackground(
        child: Stack(
          children: [
            SafeArea(
              child: tellerAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
            data: (teller) {
              if (teller == null) {
                return const Center(child: Text('Falcı bulunamadı.'));
              }
              final options = FortuneSessionDurationOption.forTeller(teller);
              final selected = options.firstWhere(
                (o) => o.minutes == _selectedMinutes,
                orElse: () => options[1],
              );
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppThemeColors.accentPink,
                                AppThemeColors.accentPurple,
                              ],
                            ),
                          ),
                          child: teller.avatarUrl != null &&
                                  teller.avatarUrl!.isNotEmpty
                              ? CircleAvatar(
                                  radius: 52,
                                  backgroundImage: CachedNetworkImageProvider(
                                    teller.avatarUrl!,
                                  ),
                                )
                              : const UserAvatar(radius: 52),
                        ),
                        if (teller.isOnline)
                          const Positioned(
                            right: 6,
                            bottom: 6,
                            child: LiveBadge(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        teller.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified_rounded,
                        color: AppThemeColors.diamondBlue,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      if (teller.isOnline)
                        _Pill(
                          label: 'Çevrimiçi',
                          color: const Color(0xFF00E676),
                        ),
                      if (teller.rating > 0)
                        _Pill(
                          label: '★ ${teller.rating.toStringAsFixed(1)}',
                          color: const Color(0xFFFFD54F),
                          foreground: Colors.black87,
                        ),
                      _Pill(
                        label: '${teller.reviewCount} seans',
                        color: Colors.white24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    teller.displayCategory,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.colors.onSurfaceMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💰 ${selected.jetonPerMinute} jeton/dk',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (teller.bio != null && teller.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      teller.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.4,
                        color: context.colors.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Randevu Al',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Süre Seçin',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.55,
                    ),
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final o = options[i];
                      final active = o.minutes == _selectedMinutes;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _selectedMinutes = o.minutes),
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: active
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFB832FF),
                                        Color(0xFFFF0080),
                                      ],
                                    )
                                  : null,
                              color: active
                                  ? null
                                  : Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: active
                                    ? Colors.transparent
                                    : AppThemeColors.accentPurple
                                        .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  o.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: active
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${o.totalJeton} jeton',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? const Color(0xFFFFD54F)
                                        : const Color(0xFFFFD54F)
                                            .withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${selected.jetonPerMinute} jeton/dk · Toplam: ${selected.totalJeton} jeton',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Mevcut Jetonunuz:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '$balance jeton',
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: teller.isOnline && !_booking
                        ? () => _startSession(teller)
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppThemeColors.accentPurple,
                    ),
                    icon: _booking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      teller.isOnline
                          ? 'Randevu Al (${selected.totalJeton} Jeton · ${selected.minutes} dk)'
                          : 'Şu an çevrimdışı',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Icon(Icons.reviews_outlined, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Değerlendirmeler (0)',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz değerlendirme yok',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.onSurfaceMuted),
                  ),
                ],
              );
            },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 8),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    tooltip: 'Geri',
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    this.foreground = Colors.white,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color == Colors.white24 ? 1 : 0.2),
        borderRadius: BorderRadius.circular(20),
        border: color == Colors.white24
            ? null
            : Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
