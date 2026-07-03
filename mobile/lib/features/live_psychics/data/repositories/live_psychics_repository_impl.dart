import '../../domain/entities/psychic_award_entity.dart';
import '../../domain/entities/psychic_entity.dart';
import '../../domain/entities/psychic_gift_entity.dart';
import '../../domain/entities/psychic_request_entity.dart';
import '../../domain/entities/psychic_review_entity.dart';
import '../../domain/entities/psychic_room_entity.dart';
import '../../domain/repositories/live_psychics_repository.dart';
import '../repositories/live_psychics_remote_datasource.dart';

class LivePsychicsRepositoryImpl implements LivePsychicsRepository {
  LivePsychicsRepositoryImpl(this._remote);

  final LivePsychicsRemoteDataSource _remote;

  @override
  Future<List<PsychicEntity>> fetchPsychics({
    int page = 1,
    int limit = 20,
    bool? onlineOnly,
    String? specialty,
    String? sort,
  }) =>
      _remote.fetchPsychics(
        page: page,
        limit: limit,
        onlineOnly: onlineOnly,
        specialty: specialty,
        sort: sort,
      );

  @override
  Future<PsychicEntity?> fetchPsychic(String id) => _remote.fetchPsychic(id);

  @override
  Future<PsychicEntity?> fetchMyProfile() => _remote.fetchMyProfile();

  @override
  Future<PsychicEntity?> findApprovedTellerForUser(
    String authUserId, {
    String? username,
  }) =>
      _remote.findTellerByAuthUserId(
        authUserId,
        username: username,
        maxPages: 3,
        pageLimit: 100,
      );

  @override
  Future<bool> setOnline({required bool online}) =>
      _remote.setOnline(online: online);

  @override
  Future<Map<String, dynamic>?> fetchOnlineStatus() =>
      _remote.fetchOnlineStatus();

  @override
  Future<PsychicEntity?> applyAsTeller({
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
  Future<List<PsychicReviewEntity>> fetchReviews(String tellerId) =>
      _remote.fetchReviews(tellerId);

  @override
  Future<List<PsychicAwardEntity>> fetchAwards(String tellerId) =>
      _remote.fetchAwards(tellerId);

  @override
  Future<List<PsychicGiftEntity>> fetchGifts(String tellerId) =>
      _remote.fetchGifts(tellerId);

  @override
  Future<bool> submitReview({
    required String sessionId,
    required String tellerId,
    required int rating,
    String? comment,
  }) =>
      _remote.submitReview(
        sessionId: sessionId,
        tellerId: tellerId,
        rating: rating,
        comment: comment,
      );

  @override
  Future<List<PsychicEntity>> fetchFavoritePsychics() =>
      _remote.fetchFavoritePsychics();

  @override
  Future<bool> toggleFavoritePsychic(String tellerId) =>
      _remote.toggleFavoritePsychic(tellerId);

  @override
  Future<PsychicSessionCreateResult?> createSession({
    required String tellerId,
    String? tellerUserId,
    required int durationMinutes,
    required String fortuneType,
    bool staffExempt = false,
    String? clientName,
  }) =>
      _remote.createSession(
        tellerId: tellerId,
        tellerUserId: tellerUserId,
        durationMinutes: durationMinutes,
        fortuneType: fortuneType,
        staffExempt: staffExempt,
        clientName: clientName,
      );

  @override
  Future<PsychicSessionStatusResult?> fetchSessionStatus(String sessionId) =>
      _remote.fetchSessionStatus(sessionId);

  @override
  Future<List<PsychicSessionStatusResult>> fetchActiveSessions() =>
      _remote.fetchActiveSessions();

  @override
  Future<List<PsychicRequestEntity>> fetchIncomingRequests({
    String? currentUserId,
    String? tellerProfileId,
  }) =>
      _remote.fetchIncomingRequests(
        currentUserId: currentUserId,
        tellerProfileId: tellerProfileId,
      );

  @override
  Future<PsychicRespondResult> respondSession(
    String sessionId, {
    required String action,
  }) =>
      _remote.respondSession(sessionId, action: action);

  @override
  Future<bool> endSession(String sessionId) => _remote.endSession(sessionId);

  @override
  Future<void> clearRoomSignals(String sessionId) =>
      _remote.clearRoomSignals(sessionId);

  @override
  Future<void> sendRoomSignal({
    required String sessionId,
    required String type,
    Map<String, dynamic>? data,
    String? receiverId,
  }) =>
      _remote.sendRoomSignal(
        sessionId: sessionId,
        type: type,
        data: data,
        receiverId: receiverId,
      );

  @override
  Future<PsychicRoomEntity?> fetchRoom(String sessionId) =>
      _remote.fetchRoom(sessionId);

  @override
  Future<Map<String, dynamic>?> roomAction(
    String sessionId,
    String action, {
    Map<String, dynamic>? extra,
  }) =>
      _remote.roomAction(sessionId, action, extra: extra);

  @override
  Future<List<PsychicChatMessage>> fetchMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  }) =>
      _remote.fetchMessages(sessionId, afterIso: afterIso, myUserId: myUserId);

  @override
  Future<bool> sendMessage(String sessionId, String text) =>
      _remote.sendMessage(sessionId, text);

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
    String? sessionId,
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
}
