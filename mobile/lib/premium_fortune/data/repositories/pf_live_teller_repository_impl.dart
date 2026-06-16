import '../../core/errors/pf_failure.dart';
import '../../core/result/pf_result.dart';
import '../../domain/entities/pf_fortune_teller.dart';
import '../../domain/repositories/pf_live_teller_repository.dart';
import '../datasources/pf_live_teller_datasource.dart';

class PfLiveTellerRepositoryImpl implements PfLiveTellerRepository {
  PfLiveTellerRepositoryImpl(this._datasource);

  final PfLiveTellerDatasource _datasource;

  @override
  Future<PfResult<List<PfFortuneTeller>>> getTellers() =>
      _guard(_datasource.getTellers);

  @override
  Future<PfResult<PfFortuneTeller>> getTeller(String id) =>
      _guard(() => _datasource.getTeller(id));

  @override
  Future<PfResult<PfAppointment>> bookAppointment({
    required String userId,
    required String tellerId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? notes,
  }) =>
      _guard(
        () => _datasource.bookAppointment(
          userId: userId,
          tellerId: tellerId,
          scheduledAt: scheduledAt,
          durationMinutes: durationMinutes,
          notes: notes,
        ),
      );

  @override
  Future<PfResult<String>> startVoiceCall(String userId, String tellerId) =>
      _guard(() => _datasource.startVoiceCall(userId, tellerId));

  @override
  Future<PfResult<String>> startVideoCall(String userId, String tellerId) =>
      _guard(() => _datasource.startVideoCall(userId, tellerId));

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
