import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/gift_box_remote_datasource.dart';

final giftBoxRemoteDataSourceProvider = Provider<GiftBoxRemoteDataSource>((ref) {
  return GiftBoxRemoteDataSource(ref.watch(dioProvider));
});
