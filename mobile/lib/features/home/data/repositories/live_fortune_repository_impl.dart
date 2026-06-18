import '../../../../core/network/error_handler.dart';
import '../../data/datasources/live_fortune_remote_datasource.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../../domain/entities/live_teller_review_entity.dart';
import '../../domain/repositories/live_fortune_repository.dart';

class LiveFortuneRepositoryImpl implements LiveFortuneRepository {
  LiveFortuneRepositoryImpl(this._remote);

  final LiveFortuneRemoteDataSource _remote;

  @override
  Future<List<LiveFortuneTellerEntity>> fetchTellers({
    bool? onlineOnly,
    String? specialty,
    String? sort,
  }) =>
      _remote.fetchTellers(
        onlineOnly: onlineOnly,
        specialty: specialty,
        sort: sort,
      );

  @override
  Future<LiveFortuneTellerEntity?> fetchTeller(String id) =>
      _remote.fetchTeller(id);

  @override
  Future<LiveFortuneTellerEntity?> fetchMyProfile() => _remote.fetchMyProfile();

  @override
  Future<FortuneTellerApplyResult> applyAsTeller({
    required String displayName,
    required List<String> specialties,
    String? bio,
    String? applicationNote,
  }) =>
      _remote.applyAsTeller(
        displayName: displayName,
        specialties: specialties,
        bio: bio,
        applicationNote: applicationNote,
      );

  @override
  Future<bool> setOnline({required bool online}) =>
      _remote.setOnline(online: online);

  @override
  Future<FortuneSessionCreateResult?> createSession(
    String tellerId, {
    String? tellerUserId,
    int? durationMinutes,
    int? totalJeton,
    String? fortuneType,
  }) =>
      _remote.createSession(
        tellerId,
        tellerUserId: tellerUserId,
        durationMinutes: durationMinutes,
        totalJeton: totalJeton,
        fortuneType: fortuneType,
      );

  @override
  Future<List<FortuneIncomingSession>> fetchIncomingSessions({
    String? currentUserId,
    String? tellerProfileId,
  }) =>
      _remote.fetchIncomingSessions(
        currentUserId: currentUserId,
        tellerProfileId: tellerProfileId,
      );

  @override
  Future<List<FortuneIncomingSession>> fetchPendingSessions() =>
      _remote.fetchPendingSessions();

  @override
  Future<FortuneSessionRespondResult> respondSessionDetailed(
    String sessionId, {
    required String action,
  }) =>
      _remote.respondSessionDetailed(sessionId, action: action);

  @override
  Future<FortuneSessionStatusResult?> fetchSessionStatus(String sessionId) =>
      _remote.fetchSessionStatus(sessionId);

  @override
  Future<List<FortuneSessionStatusResult>> fetchActiveSessions() =>
      _remote.fetchActiveSessions();

  @override
  Future<bool> respondSession(String sessionId, {required String action}) =>
      _remote.respondSession(sessionId, action: action);

  @override
  Future<bool> endSession(String sessionId) => _remote.endSession(sessionId);

  @override
  Future<LiveFortuneRoomInfo?> fetchRoomInfo(String sessionId) =>
      _remote.fetchRoomInfo(sessionId);

  @override
  Future<Map<String, dynamic>?> roomAction(
    String sessionId,
    String action, {
    Map<String, dynamic>? extra,
  }) =>
      _remote.roomAction(sessionId, action, extra: extra);

  @override
  Future<List<TellerChatMessage>> fetchRoomMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  }) =>
      _remote.fetchRoomMessages(
        sessionId,
        afterIso: afterIso,
        myUserId: myUserId,
      );

  @override
  Future<List<TellerChatMessage>> fetchTellerChatMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  }) =>
      _remote.fetchTellerChatMessages(
        sessionId,
        afterIso: afterIso,
        myUserId: myUserId,
      );

  @override
  Future<bool> sendRoomMessage(String sessionId, String text) =>
      _remote.sendRoomMessage(sessionId, text);

  @override
  Future<bool> extendSession({
    required String sessionId,
    required int minutes,
    required int totalJeton,
  }) =>
      _remote.extendSession(
        sessionId: sessionId,
        minutes: minutes,
        totalJeton: totalJeton,
      );

  @override
  Future<bool> tellerAddTime({
    required String sessionId,
    required int minutes,
  }) =>
      _remote.tellerAddTime(sessionId: sessionId, minutes: minutes);

  @override
  Future<bool> sendTip({
    required String sessionId,
    required int amount,
    String? tellerId,
    String? tellerUserId,
  }) =>
      _remote.sendTip(
        sessionId: sessionId,
        amount: amount,
        tellerId: tellerId,
        tellerUserId: tellerUserId,
      );

  @override
  Future<LiveTellerReviewsBundle> fetchTellerReviews(String tellerId) =>
      _remote.fetchTellerReviews(tellerId);

  @override
  Future<List<LiveTellerAwardEntity>> fetchTellerAwards(String tellerId) =>
      _remote.fetchTellerAwards(tellerId);

  @override
  Future<List<LiveTellerGiftSummaryEntity>> fetchTellerGifts(String tellerId) =>
      _remote.fetchTellerGifts(tellerId);

  @override
  Future<void> postRoomSignal({
    required String sessionId,
    required String receiverId,
    required String signalType,
    required Map<String, dynamic> signalData,
  }) =>
      _remote.postRoomSignal(
        sessionId: sessionId,
        receiverId: receiverId,
        signalType: signalType,
        signalData: signalData,
      );

  @override
  Future<List<LiveFortuneRoomSignalEntity>> pollRoomSignals(String sessionId) =>
      _remote.pollRoomSignals(sessionId);

  @override
  Future<void> clearRoomSignals(String sessionId) =>
      _remote.clearRoomSignals(sessionId);

  /// UI için merkezi hata mesajı.
  static String errorMessage(Object error) => ErrorHandler.message(error);
}
