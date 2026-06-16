import '../../core/result/pf_result.dart';
import '../entities/pf_coffee_reading.dart';

abstract interface class PfCoffeeRepository {
  Future<PfResult<List<PfCoffeeReading>>> getHistory(String userId);
  Future<PfResult<PfCoffeeReading>> analyzePhoto({
    required String userId,
    required String localImagePath,
  });
}
