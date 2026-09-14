import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPerfKey = 'cds_fx_performance_mode';

/// Dekoratif FX kapalı — blur/partikül/Lottie/shimmer azaltılır; işlevler açık kalır.
class CdsFxState {
  const CdsFxState({
    required this.performanceMode,
    required this.sessionEntranceShown,
  });

  final bool performanceMode;
  final bool sessionEntranceShown;

  bool get decorativeDisabled => performanceMode;

  CdsFxState copyWith({
    bool? performanceMode,
    bool? sessionEntranceShown,
  }) {
    return CdsFxState(
      performanceMode: performanceMode ?? this.performanceMode,
      sessionEntranceShown:
          sessionEntranceShown ?? this.sessionEntranceShown,
    );
  }
}

class CdsFxNotifier extends Notifier<CdsFxState> {
  @override
  CdsFxState build() {
    _load();
    return const CdsFxState(
      performanceMode: false,
      sessionEntranceShown: false,
    );
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final perf = prefs.getBool(_kPerfKey) ?? false;
      if (perf != state.performanceMode) {
        state = state.copyWith(performanceMode: perf);
      }
    } catch (_) {}
  }

  Future<void> setPerformanceMode(bool enabled) async {
    state = state.copyWith(performanceMode: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPerfKey, enabled);
    } catch (_) {}
  }

  void markSessionEntranceShown() {
    state = state.copyWith(sessionEntranceShown: true);
  }
}

final cdsFxProvider =
    NotifierProvider<CdsFxNotifier, CdsFxState>(CdsFxNotifier.new);

/// Kısayol — widget rebuild için watch [cdsFxProvider].
abstract final class CdsFx {
  static bool decorativeDisabled(WidgetRef ref) =>
      ref.watch(cdsFxProvider).decorativeDisabled;

  static bool sessionEntranceShown(WidgetRef ref) =>
      ref.watch(cdsFxProvider).sessionEntranceShown;
}
