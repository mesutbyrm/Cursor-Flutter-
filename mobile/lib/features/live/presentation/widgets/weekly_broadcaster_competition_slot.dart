import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/weekly_broadcaster_competition_provider.dart';
import '../providers/weekly_broadcaster_visibility_provider.dart';
import 'weekly_broadcaster_competition_card.dart';

/// Haftalık yayıncı yarışması kutusu — görünürlük ve veri kontrolü tek yerde.
///
/// Kutu önceden yalnızca `VoiceRoomRtcPage` içinde sabit bir alt-sağ konumda
/// yerleştirilmişti. Üretim derlemesi `VoiceRoomBasicPage` kullandığı için
/// sesli odalarda hiç görünmüyordu; artık iki sayfa da aynı bileşeni sağ
/// kenar kolonunda kullanıyor.
class WeeklyBroadcasterCompetitionSlot extends ConsumerWidget {
  const WeeklyBroadcasterCompetitionSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(weeklyBroadcasterCompetitionVisibleProvider);
    if (!visible) return const SizedBox.shrink();

    final competition = ref.watch(weeklyBroadcasterCompetitionProvider);
    return competition.maybeWhen(
      data: (comp) {
        // Veri yoksa sahte katılımcı/puan gösterilmez — kutu hiç çizilmez.
        if (comp == null || comp.participants.isEmpty) {
          return const SizedBox.shrink();
        }
        return WeeklyBroadcasterCompetitionCard(competition: comp);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
