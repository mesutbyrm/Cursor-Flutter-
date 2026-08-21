import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../messages/presentation/providers/conversations_list_notifier.dart';
import '../../../messages/presentation/providers/messages_providers.dart';
import '../../../messages/presentation/widgets/dm_realtime_listener.dart';
import '../../../shorts/presentation/providers/shorts_providers.dart';
import '../providers/social_providers.dart';

/// Oturum kapanışında sosyal/DM/shorts state temizliği — eski kullanıcı verisi kalmasın.
void clearSocialSessionCache(Ref ref) {
  ref.invalidate(socialNotifierProvider);
  ref.invalidate(socialStoryRingsProvider);
  ref.invalidate(conversationsListNotifierProvider);
  ref.invalidate(conversationsProvider);
  ref.read(openDmConversationIdProvider.notifier).state = null;
  ref.invalidate(shortsFeedTabProvider);
}
