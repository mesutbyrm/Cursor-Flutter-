import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/site_page_remote_datasource.dart';
import '../../domain/site_page_entity.dart';

final sitePageRemoteProvider = Provider<SitePageRemoteDataSource>((ref) {
  return SitePageRemoteDataSource(ref.watch(dioProvider));
});

final sitePageProvider =
    FutureProvider.family<SitePageEntity?, String>((ref, slug) async {
  return ref.watch(sitePageRemoteProvider).fetch(slug);
});
