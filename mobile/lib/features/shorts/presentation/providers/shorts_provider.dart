import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/shorts_datasource.dart';
import '../../data/repositories/shorts_repository_impl.dart';
import '../../domain/entities/shorts_entity.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../../../../core/providers/dio_provider.dart';

final shortsDataSourceProvider = Provider<ShortsDataSource>((ref) => ShortsDataSourceImpl(dio: ref.watch(dioProvider)));

final shortsRepositoryProvider = Provider<ShortsRepository>((ref) => ShortsRepositoryImpl(dataSource: ref.watch(shortsDataSourceProvider)));

final shortsProvider = FutureProvider<List<ShortVideo>>((ref) async => ref.watch(shortsRepositoryProvider).getShorts());

final trendingShortsProvider = FutureProvider<List<ShortVideo>>((ref) async => ref.watch(shortsRepositoryProvider).getTrendingShorts());

final shortDetailProvider = FutureProvider.family<ShortVideo, String>((ref, shortId) async => ref.watch(shortsRepositoryProvider).getShortDetail(shortId));

final remixesProvider = FutureProvider.family<List<ShortVideoRemix>, String>((ref, originalVideoId) async => ref.watch(shortsRepositoryProvider).getRemixes(originalVideoId));
