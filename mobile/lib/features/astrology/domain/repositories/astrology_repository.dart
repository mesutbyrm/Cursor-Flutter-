import '../entities/compatibility_entity.dart';
import '../entities/zodiac_sign.dart';

abstract class AstrologyRepository {
  Future<CompatibilityScore> getCompatibility(
    ZodiacSign sign1,
    ZodiacSign sign2,
  );

  Future<DailyCompatibility> getDailyCompatibility(
    ZodiacSign sign1,
    ZodiacSign sign2,
    DateTime date,
  );

  Future<List<DailyCompatibility>> getWeeklyCompatibility(
    ZodiacSign sign1,
    ZodiacSign sign2,
  );
}
