import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShareSettings {
  final String userId;
  final bool instagramEnabled;
  final bool tiktokEnabled;
  final bool twitterEnabled;
  final bool facebookEnabled;
  final bool whatsappEnabled;
  final String defaultPrivacy;
  final bool allowComments;
  final bool allowShares;

  ShareSettings({
    required this.userId,
    this.instagramEnabled = true,
    this.tiktokEnabled = true,
    this.twitterEnabled = true,
    this.facebookEnabled = true,
    this.whatsappEnabled = true,
    this.defaultPrivacy = 'public',
    this.allowComments = true,
    this.allowShares = true,
  });

  factory ShareSettings.fromJson(Map<String, dynamic> json) {
    return ShareSettings(
      userId: json['userId'] ?? '',
      instagramEnabled: json['instagramEnabled'] ?? true,
      tiktokEnabled: json['tiktokEnabled'] ?? true,
      twitterEnabled: json['twitterEnabled'] ?? true,
      facebookEnabled: json['facebookEnabled'] ?? true,
      whatsappEnabled: json['whatsappEnabled'] ?? true,
      defaultPrivacy: json['defaultPrivacy'] ?? 'public',
      allowComments: json['allowComments'] ?? true,
      allowShares: json['allowShares'] ?? true,
    );
  }
}

class ShareSettingsService {
  Future<ShareSettings> getSettings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ShareSettings(userId: userId);
  }

  Future<void> updateSettings(String userId, {
    bool? instagramEnabled,
    bool? tiktokEnabled,
    bool? twitterEnabled,
    bool? facebookEnabled,
    bool? whatsappEnabled,
    String? defaultPrivacy,
    bool? allowComments,
    bool? allowShares,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> shareToSocial(String userId, String platform, String content, {String? title}) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

final shareSettingsServiceProvider = Provider((ref) => ShareSettingsService());

final shareSettingsProvider = FutureProvider.family<ShareSettings, String>((ref, userId) async {
  final service = ref.watch(shareSettingsServiceProvider);
  return service.getSettings(userId);
});

class UpdateShareSettingsNotifier extends StateNotifier<AsyncValue<void>> {
  UpdateShareSettingsNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> updateSettings(String userId, {
    bool? instagramEnabled,
    bool? tiktokEnabled,
    bool? twitterEnabled,
    bool? facebookEnabled,
    bool? whatsappEnabled,
    String? defaultPrivacy,
    bool? allowComments,
    bool? allowShares,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(shareSettingsServiceProvider);
      await service.updateSettings(
        userId,
        instagramEnabled: instagramEnabled,
        tiktokEnabled: tiktokEnabled,
        twitterEnabled: twitterEnabled,
        facebookEnabled: facebookEnabled,
        whatsappEnabled: whatsappEnabled,
        defaultPrivacy: defaultPrivacy,
        allowComments: allowComments,
        allowShares: allowShares,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final updateShareSettingsNotifierProvider = StateNotifierProvider<UpdateShareSettingsNotifier, AsyncValue<void>>((ref) {
  return UpdateShareSettingsNotifier(ref);
});

class ShareToSocialNotifier extends StateNotifier<AsyncValue<void>> {
  ShareToSocialNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> share(String userId, String platform, String content, {String? title}) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(shareSettingsServiceProvider);
      await service.shareToSocial(userId, platform, content, title: title);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final shareToSocialNotifierProvider = StateNotifierProvider<ShareToSocialNotifier, AsyncValue<void>>((ref) {
  return ShareToSocialNotifier(ref);
});
