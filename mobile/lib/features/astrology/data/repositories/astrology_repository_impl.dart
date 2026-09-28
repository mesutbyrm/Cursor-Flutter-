import '../../domain/entities/compatibility_entity.dart';
import '../../domain/entities/zodiac_sign.dart';
import '../../domain/repositories/astrology_repository.dart';
import '../datasources/astrology_datasource.dart';

class AstrologyRepositoryImpl implements AstrologyRepository {
  final AstrologyDataSource dataSource;

  AstrologyRepositoryImpl({required this.dataSource});

  @override
  Future<CompatibilityScore> getCompatibility(
    ZodiacSign sign1,
    ZodiacSign sign2,
  ) async {
    final dto = await dataSource.getCompatibility(sign1.name, sign2.name);
    return dto.toDomain();
  }

  @override
  Future<DailyCompatibility> getDailyCompatibility(
    ZodiacSign sign1,
    ZodiacSign sign2,
    DateTime date,
  ) async {
    final dto = await dataSource.getDailyCompatibility(
      sign1.name,
      sign2.name,
      date,
    );
    return dto.toDomain();
  }

  @override
  Future<List<DailyCompatibility>> getWeeklyCompatibility(
    ZodiacSign sign1,
    ZodiacSign sign2,
  ) async {
    final dtos = await dataSource.getWeeklyCompatibility(
      sign1.name,
      sign2.name,
    );
    return dtos.map((dto) => dto.toDomain()).toList();
  }
}
