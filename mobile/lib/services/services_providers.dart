import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_provider.dart';
import '../core/sse_client_provider.dart';
import 'chat_service.dart';
import 'fortune_service.dart';
import 'game_service.dart';
import 'gift_service.dart';
import 'message_service.dart';
import 'misc_service.dart';
import 'notification_service.dart';
import 'payment_service.dart';
import 'profile_service.dart';
import 'push_service.dart';
import 'short_video_service.dart';
import 'social_service.dart';
import 'stream_service.dart';
import 'teller_service.dart';
import 'upload_service.dart';

export 'chat_service.dart';
export 'fortune_service.dart';
export 'game_service.dart';
export 'gift_service.dart';
export 'message_service.dart';
export 'misc_service.dart';
export 'notification_service.dart';
export 'payment_service.dart';
export 'profile_service.dart';
export 'push_service.dart';
export 'short_video_service.dart';
export 'social_service.dart';
export 'stream_service.dart';
export 'teller_service.dart';
export 'upload_service.dart';

export 'chat_service_provider.dart' show chatServiceProvider;
export 'stream_service_provider.dart' show streamServiceProvider;

Dio Function() _resolveDio(Ref ref) => () => ref.read(dioProvider);

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(resolveAuthedDio: _resolveDio(ref));
});

final giftServiceProvider = Provider<GiftService>((ref) {
  return GiftService(resolveAuthedDio: _resolveDio(ref));
});

final fortuneServiceProvider = Provider<FortuneService>((ref) {
  return FortuneService(sseClient: ref.watch(sseClientProvider));
});

final tellerServiceProvider = Provider<TellerService>((ref) {
  return TellerService(resolveAuthedDio: _resolveDio(ref));
});

final socialServiceProvider = Provider<SocialService>((ref) {
  return SocialService(resolveAuthedDio: _resolveDio(ref));
});

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(resolveAuthedDio: _resolveDio(ref));
});

final shortVideoServiceProvider = Provider<ShortVideoService>((ref) {
  return ShortVideoService(
    resolveAuthedDio: _resolveDio(ref),
    uploadService: ref.watch(uploadServiceProvider),
  );
});

final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService(resolveAuthedDio: _resolveDio(ref));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    resolveAuthedDio: _resolveDio(ref),
    sseClient: ref.watch(sseClientProvider),
  );
});

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(resolveAuthedDio: _resolveDio(ref));
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(resolveAuthedDio: _resolveDio(ref));
});

final gameServiceProvider = Provider<GameService>((ref) {
  return GameService(resolveAuthedDio: _resolveDio(ref));
});

final miscServiceProvider = Provider<MiscService>((ref) {
  return MiscService(resolveAuthedDio: _resolveDio(ref));
});
