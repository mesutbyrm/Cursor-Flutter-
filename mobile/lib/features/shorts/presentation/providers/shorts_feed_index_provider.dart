import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aktif feed sayfası — PageView rebuild'ini tüm listeye yaymaz.
final shortsFeedIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
