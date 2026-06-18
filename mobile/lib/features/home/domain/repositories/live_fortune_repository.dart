import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../../domain/entities/live_teller_review_entity.dart';

/// Canlı falcı modülü — üretim API sözleşmesi (canlifal.com).
abstract interface class LiveFortuneRepository {
  Future<List<LiveFortuneTellerEntity>> fetchTellers({
    bool? onlineOnly,
    String? specialty,
    String? sort,
  });

  Future<LiveFortuneTellerEntity?> fetchTeller(String id);
  Future<LiveFortuneTellerEntity?> fetchMyProfile();

  Future<FortuneTellerApplyResult> applyAsTeller({
    required String displayName,
    required List<String> specialties,
    String? bio,
    String? applicationNote,
  });

  Future<bool> setOnline({required bool online});

  Future<FortuneSessionCreateResult?> createSession(
    String tellerId, {
    String? tellerUserId,
    int? durationMinutes,
    int? totalJeton,
    String? fortuneType,
  });

  Future<List<FortuneIncomingSession>> fetchIncomingSessions({
    String? currentUserId,
    String? tellerProfileId,
  });

  Future<FortuneSessionStatusResult?> fetchSessionStatus(String sessionId);
  Future<List<FortuneSessionStatusResult>> fetchActiveSessions();

  Future<bool> respondSession(String sessionId, {required String action});
  Future<bool> endSession(String sessionId);

  Future<LiveFortuneRoomInfo?> fetchRoomInfo(String sessionId);
  Future<Map<String, dynamic>?> roomAction(
    String sessionId,
    String action, {
    Map<String, dynamic>? extra,
  });

  Future<List<TellerChatMessage>> fetchRoomMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  });

  Future<List<TellerChatMessage>> fetchTellerChatMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  });

  Future<bool> sendRoomMessage(String sessionId, String text);

  Future<bool> extendSession({
    required String sessionId,
    required int minutes,
    required int totalJeton,
  });

  Future<bool> tellerAddTime({
    required String sessionId,
    required int minutes,
  });

  Future<bool> sendTip({
    required String sessionId,
    required int amount,
    String? tellerId,
    String? tellerUserId,
  });

  Future<LiveTellerReviewsBundle> fetchTellerReviews(String tellerId);
  Future<List<LiveTellerAwardEntity>> fetchTellerAwards(String tellerId);
  Future<List<LiveTellerGiftSummaryEntity>> fetchTellerGifts(String tellerId);

  Future<void> postRoomSignal({
    required String sessionId,
    required String receiverId,
    required String signalType,
    required Map<String, dynamic> signalData,
  });

  Future<List<LiveFortuneRoomSignalEntity>> pollRoomSignals(String sessionId);
  Future<void> clearRoomSignals(String sessionId);
}
