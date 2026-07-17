import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/services_providers.dart';
import '../../../voice_hub/presentation/providers/staff_entrance_marquee_provider.dart';
import '../../../voice_hub/presentation/widgets/voice_room/voice_room_staff_join_banner.dart';

/// Ana sayfa — arama çubuğunun altında sağdan sola kayan duyuru şeridi.
/// Yetkili / Gold girişleri ve 1000+ jeton hediyeleri (site geneli).
class HomeFeedMarquee extends ConsumerStatefulWidget {
  const HomeFeedMarquee({super.key});

  @override
  ConsumerState<HomeFeedMarquee> createState() => _HomeFeedMarqueeState();
}

class _HomeFeedMarqueeState extends ConsumerState<HomeFeedMarquee> {
  Timer? _poll;
  final _seenGiftIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_pollBigGifts());
      _poll = Timer.periodic(const Duration(seconds: 20), (_) {
        unawaited(_pollBigGifts());
      });
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
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
        final sender = (raw['senderName'] ??
                raw['sender'] ??
                raw['fromName'] ??
                raw['userName'] ??
                'Biri')
            .toString();
        final receiver = (raw['receiverName'] ??
                raw['receiver'] ??
                raw['toName'] ??
                raw['targetName'] ??
                'birine')
            .toString();
        final giftName =
            (raw['giftName'] ?? raw['name'] ?? raw['gift'] ?? '').toString();
        marquee.enqueueBigGift(
          senderName: sender,
          receiverName: receiver,
          jeton: jeton > 0 ? jeton : 1000,
          giftName: giftName.isEmpty ? null : giftName,
        );
      }
    } catch (_) {}
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final message = ref.watch(
      staffEntranceMarqueeProvider.select((s) => s.message),
    );
    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: VoiceRoomStaffJoinBanner(enterBanner: message),
    );
  }
}
