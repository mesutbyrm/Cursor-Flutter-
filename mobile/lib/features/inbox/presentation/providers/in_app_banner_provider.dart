import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/domain/entities/app_notification_entity.dart';

/// Uygulama içi (foreground) bildirim türü.
enum InAppBannerKind { message, system }

/// Ekranın üstünden düşen uygulama içi bildirim olayı.
class InAppBannerEvent {
  const InAppBannerEvent({
    required this.key,
    required this.title,
    required this.body,
    required this.kind,
    required this.route,
    this.avatarUrl,
    this.notification,
    this.staffCanManagePayments = false,
  });

  /// Yinelenen bildirimleri engellemek için benzersiz anahtar (bildirim id vb.).
  final String key;
  final String title;
  final String body;
  final InAppBannerKind kind;

  /// Dokununca gidilecek yedek rota (mesaj → /chat/{peer} veya /messages).
  final String route;
  final String? avatarUrl;

  /// Varsa kanonik bildirim yönlendirmesi için kaynak bildirim. Ödeme talebi
  /// gibi tiplerde admin onay alanına (`/admin?focusRequest=`) gider.
  final AppNotificationEntity? notification;

  /// Bildirim yönlendirmesinde ödeme talepleri admin alanına gitsin mi.
  final bool staffCanManagePayments;
}

/// Herhangi bir ekranda gösterilecek tek aktif uygulama içi bildirim.
class InAppBannerController extends Notifier<InAppBannerEvent?> {
  final _recentKeys = <String>{};

  @override
  InAppBannerEvent? build() => null;

  void show(InAppBannerEvent event) {
    final key = event.key.trim();
    if (key.isNotEmpty) {
      if (!_recentKeys.add(key)) return; // aynı bildirim iki kez düşmesin
      if (_recentKeys.length > 300) _recentKeys.clear();
    }
    state = event;
  }

  void clear() {
    if (state != null) state = null;
  }
}

final inAppBannerProvider =
    NotifierProvider<InAppBannerController, InAppBannerEvent?>(
  InAppBannerController.new,
);
