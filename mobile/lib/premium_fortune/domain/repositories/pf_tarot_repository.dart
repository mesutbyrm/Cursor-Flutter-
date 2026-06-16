import '../../core/result/pf_result.dart';
import '../entities/pf_tarot_reading.dart';

abstract interface class PfTarotRepository {
  Future<PfResult<List<PfTarotReading>>> getHistory(String userId);
  Future<PfResult<PfTarotReading>> createReading({
    required String userId,
    required PfTarotMode mode,
    required List<String> selectedCardIds,
  });
  List<PfTarotCard> getDeck();
}
