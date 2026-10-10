import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../../presentation/providers/voice_gift_leaderboard_provider.dart';
import '../../data/girlive_publisher_assistant_datasource.dart';
import '../../domain/girlive_publisher_assistant_models.dart';
import '../../girlive_publisher_advice.dart';
import '../../girlive_publisher_session_metrics.dart';
import 'girlive_publisher_session_provider.dart';

class GirLivePublisherAssistantViewState {
  const GirLivePublisherAssistantViewState({
    this.loading = false,
    this.serverReport,
    this.error,
    required this.localMetrics,
    required this.grossGiftJeton,
    required this.giftCount,
    required this.tips,
    this.liveLine,
  });

  final bool loading;
  final GirLivePublisherAssistantReport? serverReport;
  final String? error;
  final GirLivePublisherSessionMetrics? localMetrics;
  final int grossGiftJeton;
  final int giftCount;
  final List<String> tips;
  final String? liveLine;

  bool get hasServer => serverReport != null;
}

class GirLivePublisherAssistantController
    extends AutoDisposeFamilyNotifier<GirLivePublisherAssistantViewState, String> {
  late String _roomKey;

  @override
  GirLivePublisherAssistantViewState build(String roomKey) {
    _roomKey = roomKey.trim();
    return GirLivePublisherAssistantViewState(
      localMetrics: ref.watch(girlivePublisherSessionProvider),
      grossGiftJeton: _grossJeton(),
      giftCount: _giftCount(),
      tips: const [],
    );
  }

  int _grossJeton() {
    final senders = ref.read(voiceSessionGiftLeaderboardProvider);
    return senders.fold<int>(0, (s, e) => s + e.totalCoins);
  }

  int _giftCount() {
    final senders = ref.read(voiceSessionGiftLeaderboardProvider);
    return senders.fold<int>(0, (s, e) => s + e.giftCount);
  }

  Future<void> refresh({String scope = 'session'}) async {
    final key = _roomKey;
    if (key.isEmpty) return;
    state = state.copyWithLoading(true, error: null);
    try {
      final ds = GirLivePublisherAssistantDataSource(ref.read(dioProvider));
      final report = await ds.fetchReport(roomId: key, scope: scope);
      final metrics = ref.read(girlivePublisherSessionProvider);
      final gross = _grossJeton();
      final count = _giftCount();
      final pkDom = metrics != null &&
          metrics.pkGiftJetonDuringPk > 0 &&
          gross > 0 &&
          metrics.pkGiftJetonDuringPk >= (gross * 0.45).round();
      final tips = report?.tips.isNotEmpty == true
          ? report!.tips
          : (metrics != null
              ? GirLivePublisherAdvice.build(
                  metrics: metrics,
                  grossGiftJeton: gross,
                  giftCount: count,
                  pkGiftsDominant: pkDom,
                )
              : const <String>[]);
      final live = metrics != null
          ? GirLivePublisherAdvice.liveStatusLine(
              metrics: metrics,
              patronOrName: 'Patron',
            )
          : null;
      state = GirLivePublisherAssistantViewState(
        loading: false,
        serverReport: report,
        localMetrics: metrics,
        grossGiftJeton: gross,
        giftCount: count,
        tips: tips,
        liveLine: live,
      );
    } catch (e) {
      state = state.copyWithLoading(false, error: e.runtimeType.toString());
    }
  }
}

extension on GirLivePublisherAssistantViewState {
  GirLivePublisherAssistantViewState copyWithLoading(
    bool loading, {
    String? error,
  }) {
    return GirLivePublisherAssistantViewState(
      loading: loading,
      serverReport: serverReport,
      error: error,
      localMetrics: localMetrics,
      grossGiftJeton: grossGiftJeton,
      giftCount: giftCount,
      tips: tips,
      liveLine: liveLine,
    );
  }
}

final girlivePublisherAssistantProvider = NotifierProvider.autoDispose
    .family<GirLivePublisherAssistantController,
        GirLivePublisherAssistantViewState, String>(
  GirLivePublisherAssistantController.new,
);
