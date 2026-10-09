import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/cds_fx.dart';

/// Tek kaynak: hareket azaltılmalı mı?
///
/// Şunlardan biri doğruysa dekoratif hareket kapalıdır, işlev aynı kalır:
/// - Sistem «animasyonları kaldır / hareketi azalt» (erişilebilirlik)
/// - Uygulama performans modu ([cdsFxProvider]; düşük donanımda varsayılan açık)
abstract final class CanlifalMotionPolicy {
  static bool reduced(BuildContext context, {required bool performanceMode}) {
    if (performanceMode) return true;
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  /// Riverpod widget'ları için kısayol — performans modu değişince yeniden çizer.
  static bool reducedOf(BuildContext context, WidgetRef ref) => reduced(
    context,
    performanceMode: ref.watch(cdsFxProvider).performanceMode,
  );
}
