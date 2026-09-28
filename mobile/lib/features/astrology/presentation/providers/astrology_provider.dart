import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/astrology_datasource.dart';
import '../../data/repositories/astrology_repository_impl.dart';
import '../../domain/entities/compatibility_entity.dart';
import '../../domain/entities/zodiac_sign.dart';
import '../../domain/repositories/astrology_repository.dart';
import '../../../../core/providers/dio_provider.dart';

// DataSource Provider
final astrologyDataSourceProvider = Provider<AstrologyDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AstrologyDataSourceImpl(dio: dio);
});

// Repository Provider
final astrologyRepositoryProvider = Provider<AstrologyRepository>((ref) {
  final dataSource = ref.watch(astrologyDataSourceProvider);
  return AstrologyRepositoryImpl(dataSource: dataSource);
});

// Compatibility Score Provider
final compatibilityScoreProvider = FutureProvider.family<
    CompatibilityScore,
    ({ZodiacSign sign1, ZodiacSign sign2})>((ref, params) async {
  final repository = ref.watch(astrologyRepositoryProvider);
  return repository.getCompatibility(params.sign1, params.sign2);
});

// Daily Compatibility Provider
final dailyCompatibilityProvider = FutureProvider.family<
    DailyCompatibility,
    ({ZodiacSign sign1, ZodiacSign sign2, DateTime date})>((ref, params) async {
  final repository = ref.watch(astrologyRepositoryProvider);
  return repository.getDailyCompatibility(
    params.sign1,
    params.sign2,
    params.date,
  );
});

// Weekly Compatibility Provider
final weeklyCompatibilityProvider = FutureProvider.family<
    List<DailyCompatibility>,
    ({ZodiacSign sign1, ZodiacSign sign2})>((ref, params) async {
  final repository = ref.watch(astrologyRepositoryProvider);
  return repository.getWeeklyCompatibility(params.sign1, params.sign2);
});

// Selected Zodiac Pair State
final selectedZodiacPairProvider =
    StateProvider<({ZodiacSign sign1, ZodiacSign sign2})?>((ref) {
  return null;
});

// Convenience Provider for current selection
final currentCompatibilityProvider =
    FutureProvider<CompatibilityScore?>((ref) async {
  final pair = ref.watch(selectedZodiacPairProvider);
  if (pair == null) return null;
  return ref.watch(compatibilityScoreProvider((
    sign1: pair.sign1,
    sign2: pair.sign2,
  )));
});
