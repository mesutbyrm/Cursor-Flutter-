import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/platform_content_remote_datasource.dart';
import '../../data/models/fortune_request_type.dart';
import '../../data/models/platform_ad.dart';
import '../../data/models/platform_popup.dart';

final platformContentRemoteDataSourceProvider =
    Provider<PlatformContentRemoteDataSource>((ref) {
  return PlatformContentRemoteDataSource(ref.watch(dioProvider));
});

final platformPopupsProvider =
    FutureProvider.autoDispose<List<PlatformPopup>>((ref) async {
  return ref.watch(platformContentRemoteDataSourceProvider).fetchPopups();
});

final activeAdsProvider =
    FutureProvider.autoDispose<List<PlatformAd>>((ref) async {
  return ref.watch(platformContentRemoteDataSourceProvider).fetchActiveAds();
});

final fortuneRequestTypesProvider =
    FutureProvider.autoDispose<List<FortuneRequestType>>((ref) async {
  return ref.watch(platformContentRemoteDataSourceProvider).fetchFortuneRequestTypes();
});

final broadcastImagesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(platformContentRemoteDataSourceProvider).fetchBroadcastImages();
});

final footballMatchesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(platformContentRemoteDataSourceProvider).fetchFootball();
});

final onlineFalSectionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(platformContentRemoteDataSourceProvider).fetchOnlineFal();
});

final appTranslationsProvider = FutureProvider.autoDispose
    .family<Map<String, String>, String>((ref, lang) async {
  return ref
      .watch(platformContentRemoteDataSourceProvider)
      .fetchTranslations(lang: lang);
});

final userLikersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(platformContentRemoteDataSourceProvider).fetchUserLikers();
});
