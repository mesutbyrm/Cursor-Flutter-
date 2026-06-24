import '../entities/psychic_award_entity.dart';
import '../entities/psychic_entity.dart';
import '../entities/psychic_gift_entity.dart';
import '../entities/psychic_request_entity.dart';
import '../entities/psychic_review_entity.dart';
import '../entities/psychic_room_entity.dart';
import '../entities/psychic_session_status.dart';

class PsychicSessionCreateResult {
  const PsychicSessionCreateResult({
    required this.sessionId,
    required this.status,
    this.tellerUserId,
    this.clientId,
    this.creditsCharged,
    this.maxMinutes,
    this.trtcRoomId,
  });

  final String sessionId;
  final PsychicSessionStatus status;
  final String? tellerUserId;
  final String? clientId;
  final int? creditsCharged;
  final int? maxMinutes;
  final String? trtcRoomId;
}

class PsychicRespondResult {
  const PsychicRespondResult({
    required this.success,
    this.sessionId,
    this.roomId,
    this.httpStatus,
    this.endpoint,
    this.responseBody,
    this.errorMessage,
  });

  final bool success;
  final String? sessionId;
  final String? roomId;
  final int? httpStatus;
  final String? endpoint;
  final String? responseBody;
  final String? errorMessage;
}

class PsychicSessionStatusResult {
  const PsychicSessionStatusResult({
    required this.sessionId,
    required this.status,
    required this.isClient,
    this.tellerUserId,
    this.tellerProfileId,
    this.trtcRoomId,
    this.durationMinutes,
    this.totalJeton,
  });

  final String sessionId;
  final PsychicSessionStatus status;
  final bool isClient;
  final String? tellerUserId;
  final String? tellerProfileId;
  final String? trtcRoomId;
  final int? durationMinutes;
  final int? totalJeton;
}

abstract class LivePsychicsRepository {
  Future<List<PsychicEntity>> fetchPsychics({
    int page = 1,
    int limit = 20,
    bool? onlineOnly,
    String? specialty,
    String? sort,
  });

  Future<PsychicEntity?> fetchPsychic(String id);
  Future<PsychicEntity?> fetchMyProfile();
  Future<PsychicEntity?> findApprovedTellerForUser(
    String authUserId, {
    String? username,
  });
  Future<bool> setOnline({required bool online});
  Future<Map<String, dynamic>?> fetchOnlineStatus();

  Future<PsychicEntity?> applyAsTeller({
    required String displayName,
    required List<String> specialties,
    String? bio,
    String? applicationNote,
  });

  Future<List<PsychicReviewEntity>> fetchReviews(String tellerId);

  Future<List<PsychicAwardEntity>> fetchAwards(String tellerId);

  Future<List<PsychicGiftEntity>> fetchGifts(String tellerId);

  Future<bool> submitReview({
    required String sessionId,
    required String tellerId,
    required int rating,
    String? comment,
  });

  Future<List<PsychicEntity>> fetchFavoritePsychics();

  /// `POST /api/favorite-tellers` — ekler veya çıkarır; yeni favori durumunu döner.
  Future<bool> toggleFavoritePsychic(String tellerId);

  Future<PsychicSessionCreateResult?> createSession({
    required String tellerId,
    String? tellerUserId,
    required int durationMinutes,
    required String fortuneType,
    bool staffExempt = false,
    String? clientName,
  });

  Future<PsychicSessionStatusResult?> fetchSessionStatus(String sessionId);
  Future<List<PsychicSessionStatusResult>> fetchActiveSessions();
  Future<List<PsychicRequestEntity>> fetchIncomingRequests({
    String? currentUserId,
    String? tellerProfileId,
  });

  Future<PsychicRespondResult> respondSession(
    String sessionId, {
    required String action,
  });

  Future<bool> endSession(String sessionId);
  Future<void> clearRoomSignals(String sessionId);
  Future<PsychicRoomEntity?> fetchRoom(String sessionId);
  Future<Map<String, dynamic>?> roomAction(
    String sessionId,
    String action, {
    Map<String, dynamic>? extra,
  });

  Future<List<PsychicChatMessage>> fetchMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  });

  Future<bool> sendMessage(String sessionId, String text);
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
}
