import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

final siteAnimationProvider = NotifierProvider.autoDispose
    .family<SiteAnimationNotifier, SiteAnimationState, String>(
  SiteAnimationNotifier.new,
);
