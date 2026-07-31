import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/sse/base_sse_service.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../presentation/providers/staff_access_provider.dart';

/// Admin ödeme istekleri SSE — web `GET /api/admin/payments/stream`.
class AdminPaymentsSseService extends BaseSseService {
  AdminPaymentsSseService() : _events = StreamController<void>.broadcast();

  final StreamController<void> _events;

  Stream<void> get onPaymentEvent => _events.stream;

  @override
  String streamPath() => ApiEndpoints.adminPaymentsStream;

  @override
  void onSseBlock(String block) {
    final map = BaseSseService.parseSseJsonBlock(block);
    if (map == null) return;
    final type = (map['type'] ?? '').toString().toLowerCase();
    if (type == 'connected' || type == 'ping' || type == 'heartbeat') return;
    if (!_events.isClosed) _events.add(null);
  }

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }
}

final adminPaymentsSseServiceProvider = Provider<AdminPaymentsSseService>((ref) {
  final service = AdminPaymentsSseService();
  ref.onDispose(service.dispose);
  return service;
});

/// Admin hub açıkken SSE bağlantısı — ödeme poll yedek kalır.
Future<void> connectAdminPaymentsSse(WidgetRef ref) async {
  final access = ref.read(staffAccessProvider);
  if (!access.canManagePayments) return;
  final storage = ref.read(tokenStorageProvider);
  final dio = ref.read(dioProvider);
  await ref.read(adminPaymentsSseServiceProvider).openConnection(
        accessToken: () async => storage.readAccess(),
        refreshTokens: () => tryRefreshAccessToken(dio, storage),
      );
}

Future<void> disconnectAdminPaymentsSse(WidgetRef ref) async {
  await ref.read(adminPaymentsSseServiceProvider).disconnect();
}
