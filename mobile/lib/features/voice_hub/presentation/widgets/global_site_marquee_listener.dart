import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../../services/services_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../providers/staff_entrance_marquee_provider.dart';

/// Site geneli kayan şerit verisi — 1000+ hediye, Gold/admin giriş, homepage ticker.
/// Ana sayfa arama altında ayrı widget yok; [StaffEntranceMarqueeHost] gösterir.
class GlobalSiteMarqueeListener extends ConsumerStatefulWidget {
  const GlobalSiteMarqueeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlobalSiteMarqueeListener> createState() =>
      _GlobalSiteMarqueeListenerState();
}

class _GlobalSiteMarqueeListenerState
    extends ConsumerState<GlobalSiteMarqueeListener> {
  Timer? _poll;
  final _seenGiftIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(StartupPerf.homeRealtimeBridgeDelay, () {
        if (!mounted) return;
        unawaited(_refresh());
        _poll = Timer.periodic(const Duration(seconds: 20), (_) {
          unawaited(_refresh());
        });
      });
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    try {
      ref.invalidate(homeTickerProvider);
      await ref.read(homeTickerProvider.future);
    } catch (_) {}
    await _pollBigGifts();
  }

  Future<void> _pollBigGifts() async {
    if (!mounted) return;
    try {
      final list = await ref.read(giftServiceProvider).getRecentBigGifts();
      final marquee = ref.read(staffEntranceMarqueeProvider.notifier);
      for (final raw in list) {
        final id = (raw['id'] ?? raw['giftId'] ?? raw['eventId'] ?? '')
            .toString()
            .trim();
        final jeton = _asInt(
          raw['totalPrice'] ??
              raw['totalCoin'] ??
              raw['jeton'] ??
              raw['amount'] ??
              raw['coinCost'] ??
              raw['price'],
        );
        if (jeton > 0 && jeton < 1000) continue;
        final key = id.isNotEmpty
            ? id
            : '${raw['senderName']}_${raw['receiverName']}_$jeton';
        if (!_seenGiftIds.add(key)) continue;
        marquee.enqueueBigGift(
          senderName: _nestedName(
            raw,
            flat: const ['senderName', 'fromName', 'userName'],
            nested: const ['sender', 'user', 'from'],
            fallback: 'Biri',
          ),
          receiverName: _nestedName(
            raw,
            flat: const ['receiverName', 'toName', 'targetName'],
            nested: const ['receiver', 'to', 'host'],
            fallback: 'birine',
          ),
          jeton: jeton > 0 ? jeton : 1000,
          giftName: () {
            final flat =
                (raw['giftName'] ?? raw['name'] ?? '').toString().trim();
            if (flat.isNotEmpty) return flat;
            final gt = raw['giftType'] ?? raw['gift'];
            if (gt is Map) {
              return (gt['name'] ?? gt['title'] ?? '').toString().trim();
            }
            return '';
          }(),
        );
      }
    } catch (_) {}
  }

  static String _nestedName(
    Map<String, dynamic> raw, {
    required List<String> flat,
    required List<String> nested,
    required String fallback,
  }) {
    for (final k in flat) {
      final v = raw[k]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    for (final k in nested) {
      final obj = raw[k];
      if (obj is Map) {
        final v = (obj['name'] ?? obj['displayName'] ?? obj['username'] ?? '')
            .toString()
            .trim();
        if (v.isNotEmpty) return v;
      } else if (obj != null) {
        final v = obj.toString().trim();
        if (v.isNotEmpty) return v;
      }
    }
    return fallback;
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
