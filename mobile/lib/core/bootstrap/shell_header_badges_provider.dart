import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ana sayfa üst bar rozetleri — ilk kareden sonra API tetiklenir.
final shellHeaderBadgesEnabledProvider = StateProvider<bool>((ref) => false);

void enableShellHeaderBadges(WidgetRef ref) {
  if (ref.read(shellHeaderBadgesEnabledProvider)) return;
  ref.read(shellHeaderBadgesEnabledProvider.notifier).state = true;
}
