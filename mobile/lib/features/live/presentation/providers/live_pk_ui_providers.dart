import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PK sırasında karşı yayıncının sesi yerel olarak kapatıldı mı?
final livePkOpponentMutedProvider =
    StateProvider.autoDispose.family<bool, String>((ref, streamId) => false);
