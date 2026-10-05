import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../animations/animation_payload.dart';
import '../../animations/animations_repository.dart';
import '../domain/site_animation_asset.dart';
import '../domain/site_animation_layout.dart';
import '../application/site_animation_manager.dart';
import '../application/site_animation_state.dart';
import '../data/site_animation_parser.dart';
import '../data/site_animation_resolver.dart';
import '../domain/site_animation_catalog_entry.dart';
import '../domain/site_animation_command.dart';
import '../domain/site_animation_type.dart';
import 'site_animation_catalog_provider.dart';
import 'site_animation_realtime_policy.dart';

class SiteAnimationNotifier
    extends AutoDisposeFamilyNotifier<SiteAnimationState, String> {
  late SiteAnimationManager _manager;

  @override
  SiteAnimationState build(String roomId) {
    ref.watch(siteAnimationCatalogProvider);
    _manager = SiteAnimationManager(
      onStateChanged: (next) {
        state = next;
      },
    );
    ref.onDispose(_manager.dispose);
    return _manager.state;
  }

  SiteAnimationManager get manager => _manager;

  void handleRoomEvent(String event, Map<String, dynamic> payload,
      {String? ownerId}) {
    // Giriş/çıkış: önce merkezi animasyon sistemi (backend çözümleyicisi);
    // kullanıcıya atanmış animasyon yoksa eski katalog/tema akışı çalışır.
    final base = SiteAnimationParser.fromRoomEvent(
      roomId: arg,
      event: event,
      payload: payload,
      ownerId: ownerId,
    );
    if (base != null &&
        (base.type.isEntrance || base.type.isExit) &&
        !_shouldSuppressSelfEntrance(base) &&
        base.userId.trim().isNotEmpty) {
      unawaited(_playResolved(base, event, payload, ownerId));
      return;
    }
    _handleLegacy(event, payload, ownerId: ownerId);
  }

  Future<void> _playResolved(
    SiteAnimationCommand base,
    String event,
    Map<String, dynamic> payload,
    String? ownerId,
  ) async {
    AnimationPayload? resolved;
    try {
      resolved = await ref
          .read(animationsRepositoryProvider)
          .resolve(
            userId: base.userId,
            category: base.type.isEntrance ? 'entrance' : 'exit',
            context: arg.startsWith('ctx_live') ? 'live_stream' : 'voice_room',
          )
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
    if (resolved == null) {
      _handleLegacy(event, payload, ownerId: ownerId);
      return;
    }
    final kind = switch (resolved.type) {
      'lottie' => SiteAnimationMediaKind.lottie,
      'video' => SiteAnimationMediaKind.video,
      'svga' => SiteAnimationMediaKind.svga,
      _ => SiteAnimationMediaKind.image,
    };
    final dur = resolved.durationMs.clamp(1500, 6000);
    _manager.play(
      base.copyWith(
        asset: SiteAnimationAsset(url: resolved.resolvedAssetUrl, kind: kind),
        layout: SiteAnimationLayout(
          anchor: base.layout.anchor,
          scale: resolved.scaleFactor,
          durationMs: dur,
        ),
        soundUrl: resolved.resolvedSoundUrl,
        animationId: resolved.animationId,
        priorityOverride: resolved.priority,
        cooldownMs: resolved.cooldownMs,
      ),
    );
  }

  void _handleLegacy(String event, Map<String, dynamic> payload,
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
        if ((base.type.isEntrance || base.type.isExit) &&
            (!activeGoldEntranceMembershipFromPayload(payload) ||
                !siteAnimationTierAllowsEntranceExit(base.tier))) {
          return null;
        }
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
