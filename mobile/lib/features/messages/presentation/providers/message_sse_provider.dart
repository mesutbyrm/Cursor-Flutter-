import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/message_sse_service.dart';

final messageSseServiceProvider = Provider<MessageSseService>((ref) {
  final service = MessageSseService();
  ref.onDispose(service.dispose);
  return service;
});
