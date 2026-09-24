import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Haftalık yayıncı yarışması kartının görünürlüğü.
final weeklyBroadcasterCompetitionVisibleProvider =
    StateProvider.autoDispose<bool>((ref) {
  return true; // Varsayılan olarak göster
});
