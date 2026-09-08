import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_controller_provider.dart';
import '../data/site_animation_parser.dart';
import '../data/site_animation_resolver.dart';
import '../domain/site_animation_catalog_entry.dart';
import '../domain/site_animation_command.dart';
import 'site_animation_catalog_provider.dart';
import 'site_animation_manager.dart';
import 'site_animation_state.dart';

class SiteAnimationNotifier
    extends AutoDisposeFamilyNotifier<SiteAnimationState, String> {
  late SiteAnimationManager _manager;

  @override
  SiteAnimationState build(String roomId) {
    ref.watch(siteAnimationCatalogProvider);
    _manager = SiteAnimationManager(
      onStateChanged: (next) {
        if (!ref.mounted) return;
        state = next;
      },
    );
    ref.onDispose(_manager.dispose);
    return _manager.state;
  }

  SiteAnimationManager get manager => _manager;

  void handleRoomEvent(String event, Map<String, dynamic> payload,
      {String? ownerId}) {
    _manager.handleRoomEvent(
      event,
      payload,
      roomId: arg,
      ownerId: ownerId,
      parse: () {
        final base = SiteAnimationParser.fromRoomEvent(
          roomId: arg,
          event: event,
          payload: payload,
          ownerId: ownerId,
        );
        if (base == null) return null;
        if (_shouldSuppressSelfEntrance(base)) return null;
        final catalog = ref.read(siteAnimationCatalogProvider).valueOrNull ??
            const SiteAnimationCatalogSnapshot();
        return SiteAnimationResolver.resolve(base: base, catalog: catalog);
      },
    );
  }

  void play(SiteAnimationCommand command) => _manager.play(command);

  void queue(SiteAnimationCommand command) => _manager.queue(command);

  void cancel(String eventId) => _manager.cancel(eventId);

  void clearQueue() => _manager.clearQueue();

  Future<void> preload(SiteAnimationCommand command) =>
      _manager.preload(command.asset);

  void onActiveFinished(String eventId) => _manager.onActiveFinished(eventId);

  /// Kullanıcı kendi giriş kartını görmez — spec §22.
  bool _shouldSuppressSelfEntrance(SiteAnimationCommand base) {
    return shouldSuppressSelfEntranceAnimation(
      command: base,
      currentUserId: ref.read(authControllerProvider).valueOrNull?.id,
    );
  }
}

/// Test edilebilir self-entrance filtresi.
bool shouldSuppressSelfEntranceAnimation({
  required SiteAnimationCommand command,
  required String? currentUserId,
}) {
  if (!command.type.isEntrance) return false;
  if (currentUserId == null || currentUserId.isEmpty) return false;
  return command.userId == currentUserId;
}

final siteAnimationProvider = NotifierProvider.autoDispose
    .family<SiteAnimationNotifier, SiteAnimationState, String>(
  SiteAnimationNotifier.new,
);
