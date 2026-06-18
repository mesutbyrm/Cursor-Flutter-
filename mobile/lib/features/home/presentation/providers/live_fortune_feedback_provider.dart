import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Danışan profil sayfasında gösterilecek kısa geri bildirim (ör. red mesajı).
final liveFortuneBookingFeedbackProvider =
    StateProvider<String?>((ref) => null);
