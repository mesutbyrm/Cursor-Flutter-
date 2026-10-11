import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/admin_girlive_bot_config.dart';
import 'admin_panel_providers.dart';

final adminGirLiveBotConfigProvider =
    FutureProvider.autoDispose<AdminGirLiveBotPublicMessages>((ref) async {
  return ref.read(adminRemoteProvider).fetchGirLiveBotPublicMessages();
});
