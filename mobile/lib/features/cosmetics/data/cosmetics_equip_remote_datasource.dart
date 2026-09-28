import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../vip_gold/domain/vip_tier.dart';
import '../domain/cosmetic_effect_kind.dart';
import '../domain/cosmetic_item.dart';
import '../domain/cosmetic_slot.dart';
import '../domain/user_cosmetic_loadout.dart';

/// Yuva başına canlifal kozmetik uçları. `profileEffect` ve `badge` için backend
/// seçimi yoktur; bunlar cihazda kalır.
class CosmeticsEquipRemoteDataSource {
  CosmeticsEquipRemoteDataSource(this._dio);

  final Dio _dio;

  static String? endpointFor(CosmeticSlot slot) => switch (slot) {
        CosmeticSlot.profileFrame => ApiEndpoints.profileFrames,
        CosmeticSlot.microphoneFrame => ApiEndpoints.micFrames,
        CosmeticSlot.chatBubble => ApiEndpoints.chatBubbles,
        CosmeticSlot.nameEffect => ApiEndpoints.nameEffects,
        CosmeticSlot.entranceAnimation => ApiEndpoints.entranceEffects,
        CosmeticSlot.avatarAccessory => ApiEndpoints.avatarAccessories,
        CosmeticSlot.profileEffect || CosmeticSlot.badge => null,
      };

  static const syncedSlots = [
    CosmeticSlot.profileFrame,
    CosmeticSlot.microphoneFrame,
    CosmeticSlot.chatBubble,
    CosmeticSlot.nameEffect,
    CosmeticSlot.entranceAnimation,
    CosmeticSlot.avatarAccessory,
  ];

  /// `createCosmeticPublicHandlers` zarfı: `{success, data: {items, selected}}`;
  /// profil çerçevesi: `{frames, currentFrameId}`.
  static ({List<Map<String, dynamic>> items, dynamic selected}) parseSlotBody(
    CosmeticSlot slot,
    dynamic body,
  ) {
    final root = asJsonMap(body);
    if (slot == CosmeticSlot.profileFrame) {
      return (items: asJsonList(root['frames']), selected: root['currentFrameId']);
    }
    final data = root['data'] is Map ? asJsonMap(root['data']) : root;
    return (items: asJsonList(data['items']), selected: data['selected']);
  }

  static CosmeticItem itemFromBackend(CosmeticSlot slot, Map<String, dynamic> m) {
    final isName = slot == CosmeticSlot.nameEffect;
    final key = m['key']?.toString() ?? '';
    final asset = (m['assetUrl'] ?? m['imageUrl'])?.toString();
    return CosmeticItem(
      id: isName ? key : (m['id']?.toString() ?? ''),
      slot: slot,
      name: m['name']?.toString() ?? slot.labelTr,
      effectKind: isName
          ? (CosmeticEffectKindX.parse('${key}Text') ?? CosmeticEffectKind.glowText)
          : CosmeticEffectKind.imageOverlay,
      previewUrl: asset,
      assetUrl: asset,
      requiredTier: VipTier.fromMembership(m['tier']?.toString()),
      sortOrder: asInt(m['sortOrder']),
      active: m['isActive'] != false && m['tier']?.toString() != 'admin_only',
    );
  }

  Future<({List<CosmeticItem> items, String? selected})?> fetchSlot(
    CosmeticSlot slot,
  ) async {
    final path = endpointFor(slot);
    if (path == null) return null;
    try {
      final res = await _dio.safeGet<dynamic>(path, forceRefresh: true);
      final parsed = parseSlotBody(slot, res.data);
      final sel = parsed.selected;
      return (
        items: parsed.items
            .map((m) => itemFromBackend(slot, m))
            .where((c) => c.id.isNotEmpty && c.active)
            .toList(),
        selected: sel is List
            ? (sel.isEmpty ? null : sel.first.toString())
            : sel?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<UserCosmeticLoadout?> fetchRemoteLoadout() async {
    final results = await Future.wait(syncedSlots.map(fetchSlot));
    final equipped = <CosmeticSlot, String>{};
    var any = false;
    for (var i = 0; i < syncedSlots.length; i++) {
      final r = results[i];
      if (r == null) continue;
      any = true;
      final sel = r.selected?.trim();
      if (sel != null && sel.isNotEmpty) equipped[syncedSlots[i]] = sel;
    }
    return any ? UserCosmeticLoadout(equipped: equipped) : null;
  }

  /// Yerel katalog öğeleri backend'de yoksa 404 döner; sessiz geçilir.
  Future<void> pushEquip(
    CosmeticSlot slot,
    String? itemId, {
    String? previousId,
  }) async {
    final path = endpointFor(slot);
    if (path == null) return;
    final opts = Options(validateStatus: (s) => s != null && s < 500);
    try {
      if (slot == CosmeticSlot.profileFrame) {
        await _dio.safePost<dynamic>(path, data: {'frameId': itemId}, options: opts);
        return;
      }
      if (slot == CosmeticSlot.avatarAccessory) {
        // Çoklu seçim: varsayılan toggle; önce eskisini çıkar, sonra yenisini ekle.
        if (previousId != null && previousId != itemId) {
          await _dio.safePost<dynamic>(path, data: {'id': previousId}, options: opts);
        }
        if (itemId != null) {
          await _dio.safePost<dynamic>(
            path,
            data: {'id': itemId, 'toggle': false},
            options: opts,
          );
        }
        return;
      }
      await _dio.safePost<dynamic>(path, data: {'id': itemId}, options: opts);
    } catch (_) {}
  }
}
