import '../../core/result/pf_result.dart';
import '../entities/pf_fortune_teller.dart';

abstract interface class PfLiveTellerRepository {
  Future<PfResult<List<PfFortuneTeller>>> getTellers();
  Future<PfResult<PfFortuneTeller>> getTeller(String id);
  Future<PfResult<PfAppointment>> bookAppointment({
    required String userId,
    required String tellerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? notes,
  });
  Future<PfResult<String>> startVoiceCall(String userId, String tellerId);
  Future<PfResult<String>> startVideoCall(String userId, String tellerId);
}
