import '../../core/result/pf_result.dart';
import '../entities/pf_astrology.dart';

abstract interface class PfAstrologyRepository {
  Future<PfResult<PfHoroscopeReading>> getHoroscope(String sign);
  Future<PfResult<PfBirthChart>> createBirthChart({
    required String userId,
    required DateTime birthDate,
    required String birthPlace,
    required double latitude,
    required double longitude,
  });
}
