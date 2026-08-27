import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kullanıcının canlı yayınları için global PK — Socket.IO yok.
/// Davetler stream SSE (`onPkBattle`) ve bildirim kanalından gelir.
final livePkOwnedStreamsSocketProvider = Provider<void>((ref) {});
