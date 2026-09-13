import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/gift_box_remote_datasource.dart';
import '../../data/repositories/gift_box_repository_impl.dart';
import '../../domain/repositories/gift_box_repository.dart';

final giftBoxRemoteDataSourceProvider = Provider<GiftBoxRemoteDataSource>((ref) {
  return GiftBoxRemoteDataSource(ref.watch(dioProvider));
});

final giftBoxRepositoryProvider = Provider<GiftBoxRepository>((ref) {
  return GiftBoxRepositoryImpl(ref.watch(giftBoxRemoteDataSourceProvider));
});
