import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/social_discovery_remote_datasource.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../../domain/entities/user_location_settings.dart';

final socialDiscoveryRemoteProvider =
    Provider<SocialDiscoveryRemoteDataSource>((ref) {
  return SocialDiscoveryRemoteDataSource(ref.watch(dioProvider));
});

final socialDiscoveryFeedProvider =
    FutureProvider.autoDispose<List<SocialDiscoveryUser>>((ref) async {
  return ref.read(socialDiscoveryRemoteProvider).fetchDiscovery();
});

final userLocationSettingsProvider =
    FutureProvider.autoDispose<UserLocationSettings>((ref) async {
  return ref.read(socialDiscoveryRemoteProvider).fetchLocationSettings();
});
