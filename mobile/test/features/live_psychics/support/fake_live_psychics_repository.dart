import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_award_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_gift_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_request_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_review_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_room_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_history_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';

/// Minimal fake for push-flow unit tests.
class FakeLivePsychicsRepository implements LivePsychicsRepository {
  FakeLivePsychicsRepository({
    this.statusResult,
    this.roomResult,
    this.psychicResult,
  });

  PsychicSessionStatusResult? statusResult;
  PsychicRoomEntity? roomResult;
  PsychicEntity? psychicResult;
  PsychicRespondResult respondResult = const PsychicRespondResult(success: true);
  String? lastRespondAction;
  String? lastRespondSessionId;

  @override
  Future<PsychicRespondResult> respondSession(
    String sessionId, {
    required String action,
  }) async {
    lastRespondSessionId = sessionId;
    lastRespondAction = action;
    return PsychicRespondResult(
      success: respondResult.success,
      sessionId: sessionId,
      roomId: respondResult.roomId,
      httpStatus: respondResult.httpStatus,
      endpoint: respondResult.endpoint,
      responseBody: respondResult.responseBody,
      errorMessage: respondResult.errorMessage,
    );
  }

  @override
  Future<PsychicSessionStatusResult?> fetchSessionStatus(String sessionId) async =>
      statusResult;

  @override
  Future<PsychicRoomEntity?> fetchRoom(String sessionId) async => roomResult;

  @override
  Future<PsychicEntity?> fetchPsychic(String id) async => psychicResult;

  @override
  Future<List<PsychicEntity>> fetchPsychics({
    int page = 1,
    int limit = 20,
    bool? onlineOnly,
    String? specialty,
    String? sort,
  }) =>
      throw UnimplementedError();

  @override
  Future<PsychicEntity?> fetchMyProfile() => throw UnimplementedError();

  @override
  Future<PsychicEntity?> findApprovedTellerForUser(
    String authUserId, {
    String? username,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> setOnline({required bool online}) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchOnlineStatus() => throw UnimplementedError();

  @override
  Future<PsychicEntity?> applyAsTeller({
    required String displayName,
    required List<String> specialties,
    String? bio,
    String? applicationNote,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<PsychicReviewEntity>> fetchReviews(String tellerId) =>
      throw UnimplementedError();

  @override
  Future<List<PsychicAwardEntity>> fetchAwards(String tellerId) =>
      throw UnimplementedError();

  @override
  Future<List<PsychicGiftEntity>> fetchGifts(String tellerId) =>
      throw UnimplementedError();

  @override
  Future<bool> submitReview({
    required String sessionId,
    required String tellerId,
    required int rating,
    String? comment,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<PsychicEntity>> fetchFavoritePsychics() => throw UnimplementedError();

  @override
  Future<bool> toggleFavoritePsychic(String tellerId) => throw UnimplementedError();

  @override
  Future<PsychicSessionCreateResult?> createSession({
    required String tellerId,
    required int durationMinutes,
    required String fortuneType,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<PsychicSessionHistoryEntity>> fetchRecentSessions({int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<List<PsychicSessionStatusResult>> fetchActiveSessions() =>
      throw UnimplementedError();

  @override
  Future<List<PsychicRequestEntity>> fetchIncomingRequests({
    String? currentUserId,
    String? tellerProfileId,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> cancelSession(String sessionId) => throw UnimplementedError();

  @override
  Future<bool> endSession(String sessionId) => throw UnimplementedError();

  @override
  Future<void> clearRoomSignals(String sessionId) => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchRoomSignals(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<void> sendRoomSignal({
    required String sessionId,
    required String type,
    Map<String, dynamic>? data,
    String? receiverId,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<PsychicChatMessage>> fetchMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> sendMessage(String sessionId, String text) =>
      throw UnimplementedError();

  @override
  Future<bool> extendSession({
    required String sessionId,
    required int minutes,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> tellerAddTime({
    required String sessionId,
    required int minutes,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> sendTip({
    String? sessionId,
    required int amount,
    String? tellerId,
    String? tellerUserId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> roomAction(
    String sessionId,
    String action, {
    Map<String, dynamic>? extra,
  }) =>
      throw UnimplementedError();
}
