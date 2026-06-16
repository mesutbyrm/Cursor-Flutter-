import '../../core/errors/pf_failure.dart';
import '../../core/result/pf_result.dart';
import '../../domain/entities/pf_astrology.dart';
import '../../domain/repositories/pf_astrology_repository.dart';
import '../datasources/pf_astrology_datasource.dart';

class PfAstrologyRepositoryImpl implements PfAstrologyRepository {
  PfAstrologyRepositoryImpl(this._datasource);

  final PfAstrologyDatasource _datasource;

  @override
  Future<PfResult<PfHoroscopeReading>> getHoroscope(String sign) =>
      _guard(() => _datasource.getHoroscope(sign));

  @override
  Future<PfResult<PfBirthChart>> createBirthChart({
    required String userId,
    required DateTime birthDate,
    required String birthPlace,
    required double latitude,
    required double longitude,
  }) =>
      _guard(
        () => _datasource.createBirthChart(
          userId: userId,
          birthDate: birthDate,
          birthPlace: birthPlace,
          latitude: latitude,
          longitude: longitude,
        ),
      );

  Future<PfResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return PfSuccess(await action());
    } on PfFailure catch (e) {
      return PfError(e);
    } catch (e) {
      return PfError(PfNetworkFailure(e.toString()));
    }
  }
}
