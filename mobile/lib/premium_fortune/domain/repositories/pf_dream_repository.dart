import '../../core/result/pf_result.dart';
import '../entities/pf_dream_reading.dart';

abstract interface class PfDreamRepository {
  Future<PfResult<List<PfDreamReading>>> getHistory(String userId);
  Future<PfResult<PfDreamReading>> interpretDream({
    required String userId,
    required String dreamText,
  });
}
