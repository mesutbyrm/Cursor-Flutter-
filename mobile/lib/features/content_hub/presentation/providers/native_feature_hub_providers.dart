import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../home/data/datasources/mobile_compound_remote_datasource.dart';
import '../../data/native_feature_remote_datasource.dart';
import '../../domain/native_feature_item.dart';

final nativeFeatureRemoteProvider = Provider<NativeFeatureRemoteDataSource>((
  ref,
) {
  return NativeFeatureRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(mobileCompoundRemoteProvider),
  );
});

final nativeFeatureItemsProvider = FutureProvider.autoDispose
    .family<List<NativeFeatureItem>, NativeFeatureHubKind>((ref, kind) {
      return ref.watch(nativeFeatureRemoteProvider).fetch(kind);
    });
