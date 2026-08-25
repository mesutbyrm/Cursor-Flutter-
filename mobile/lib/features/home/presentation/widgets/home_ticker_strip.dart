import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import '../../../gifts/domain/homepage_gift_ticker.dart';

/// Arama çubuğu altında kayan yazı — hediye duyuruları burada dönmez.
class HomeTickerStrip extends ConsumerStatefulWidget {
  const HomeTickerStrip({super.key});

  @override
  ConsumerState<HomeTickerStrip> createState() => _HomeTickerStripState();
}

class _HomeTickerStripState extends ConsumerState<HomeTickerStrip> {
  Timer? _rotate;
  var _index = 0;
  var _lineCount = 0;

  @override
  void dispose() {
    _rotate?.cancel();
    super.dispose();
  }

  void _ensureRotateTimer(int count) {
    if (count == _lineCount) return;
    _lineCount = count;
    _rotate?.cancel();
    _index = 0;
    if (count <= 1) return;
    _rotate = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % count);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticker = ref.watch(homeTickerProvider);
    return ticker.when(
      loading: () => const SizedBox(height: 4),
      error: (_, _) => const SizedBox.shrink(),
      data: (rawLines) {
        final lines = HomepageGiftTicker.newsLines(rawLines);
        if (lines.isEmpty) return const SizedBox.shrink();
        _ensureRotateTimer(lines.length);
        if (_index >= lines.length) _index = 0;
        final line = lines[_index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            HomeApprovedDesign.hPad,
            0,
            HomeApprovedDesign.hPad,
            8,
          ),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: HomeApprovedDesign.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: HomeApprovedDesign.purple.withValues(alpha: 0.25),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 16,
                  color: HomeApprovedDesign.purple.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      line,
                      key: ValueKey(line),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: HomeApprovedDesign.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
