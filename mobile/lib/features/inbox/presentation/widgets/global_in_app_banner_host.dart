import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../providers/in_app_banner_provider.dart';

/// Uygulama içi bildirim host'u — mesaj veya sistem bildirimi geldiğinde
/// kullanıcı hangi ekranda olursa olsun ekranın üstünden düşen banner.
/// Shell Stack'inde en üstte mount edilir.
class GlobalInAppBannerHost extends ConsumerStatefulWidget {
  const GlobalInAppBannerHost({super.key});

  @override
  ConsumerState<GlobalInAppBannerHost> createState() =>
      _GlobalInAppBannerHostState();
}

class _GlobalInAppBannerHostState extends ConsumerState<GlobalInAppBannerHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  InAppBannerEvent? _current;
  Timer? _dismiss;

  static const _visibleFor = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _dismiss?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _present(InAppBannerEvent event) {
    _dismiss?.cancel();
    setState(() => _current = event);
    _anim.forward(from: 0);
    _dismiss = Timer(_visibleFor, _hide);
  }

  void _hide() {
    _dismiss?.cancel();
    _dismiss = null;
    if (!mounted) return;
    _anim.reverse().whenComplete(() {
      if (mounted) setState(() => _current = null);
    });
    ref.read(inAppBannerProvider.notifier).clear();
  }

  void _openAndHide(InAppBannerEvent event) {
    _hide();
    ref.read(goRouterProvider).push(event.route);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InAppBannerEvent?>(inAppBannerProvider, (prev, next) {
      if (next != null) _present(next);
    });

    final event = _current;
    if (event == null) return const SizedBox.shrink();

    final topPad = MediaQuery.paddingOf(context).top;
    final isMessage = event.kind == InAppBannerKind.message;
    final accent =
        isMessage ? AppThemeColors.accentCyan : AppThemeColors.accentPurple;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, topPad + 8, 10, 0),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < 0) _hide();
              },
              onTap: () => _openAndHide(event),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0F2E).withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withValues(alpha: 0.55)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.18),
                        border: Border.all(color: accent.withValues(alpha: 0.5)),
                        image: (event.avatarUrl?.isNotEmpty ?? false)
                            ? DecorationImage(
                                image: NetworkImage(event.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: (event.avatarUrl?.isNotEmpty ?? false)
                          ? null
                          : Icon(
                              isMessage
                                  ? Icons.forum_rounded
                                  : Icons.notifications_rounded,
                              color: accent,
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.title.isNotEmpty
                                ? event.title
                                : (isMessage ? 'Yeni mesaj' : 'Bildirim'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          if (event.body.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                event.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                  height: 1.25,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
