import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_provider.dart';
import '../core/sse_client_provider.dart';
import 'auth_service_provider.dart';
import 'chat_service.dart';
import 'config_service.dart';
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
import 'user_service.dart';

export 'chat_service.dart';
export 'config_service.dart';
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
export 'user_service.dart';

export 'auth_service_provider.dart' show authServiceProvider, authPublicDioProvider;
export 'chat_service_provider.dart' show chatServiceProvider;
export 'stream_service_provider.dart' show streamServiceProvider;

Dio Function() _resolveDio(Ref ref) => () => ref.read(dioProvider);

final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService(publicDio: ref.watch(authPublicDioProvider));
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(resolveAuthedDio: _resolveDio(ref));
});

@Deprecated('Migrate to feature repositories — legacy services/')
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(resolveAuthedDio: _resolveDio(ref));
});

@Deprecated('Use giftRepositoryProvider — legacy services/')
final giftServiceProvider = Provider<GiftService>((ref) {
  return GiftService(resolveAuthedDio: _resolveDio(ref));
});

@Deprecated('Migrate to feature repositories — legacy services/')
final fortuneServiceProvider = Provider<FortuneService>((ref) {
  return FortuneService(sseClient: ref.watch(sseClientProvider));
});

@Deprecated('Migrate to feature repositories — legacy services/')
final tellerServiceProvider = Provider<TellerService>((ref) {
  return TellerService(resolveAuthedDio: _resolveDio(ref));
});

@Deprecated('Use socialRepositoryProvider — legacy services/')
final socialServiceProvider = Provider<SocialService>((ref) {
  return SocialService(resolveAuthedDio: _resolveDio(ref));
});

@Deprecated('Migrate to feature repositories — legacy services/')
final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(resolveAuthedDio: _resolveDio(ref));
});

@Deprecated('Migrate to feature repositories — legacy services/')
final shortVideoServiceProvider = Provider<ShortVideoService>((ref) {
  return ShortVideoService(
    resolveAuthedDio: _resolveDio(ref),
    uploadService: ref.watch(uploadServiceProvider),
  );
});

@Deprecated('Use messagesRepositoryProvider — legacy services/')
final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService(resolveAuthedDio: _resolveDio(ref));
});

@Deprecated('Migrate to feature repositories — legacy services/')
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    resolveAuthedDio: _resolveDio(ref),
    sseClient: ref.watch(sseClientProvider),
  );
});

@Deprecated('Migrate to feature repositories — legacy services/')
final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(resolveAuthedDio: _resolveDio(ref));
});

@Deprecated('Migrate to feature repositories — legacy services/')
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(resolveAuthedDio: _resolveDio(ref));
});

@Deprecated('Migrate to feature repositories — legacy services/')
final gameServiceProvider = Provider<GameService>((ref) {
  return GameService(resolveAuthedDio: _resolveDio(ref));
});

@Deprecated('Migrate to feature repositories — legacy services/')
final miscServiceProvider = Provider<MiscService>((ref) {
  return MiscService(resolveAuthedDio: _resolveDio(ref));
});
