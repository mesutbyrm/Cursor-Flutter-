import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sesli oda giriş teşhisi — JWT, TRTC, SSE, socket ve son hatalar.
class VoiceRoomDiagnosticState {
  const VoiceRoomDiagnosticState({
    this.roomId = '',
    this.hasJwt = false,
    this.presenceJoined = false,
    this.presenceCount = 0,
    this.sseConnected = false,
    this.socketConnected = false,
    this.trtcEntered = false,
    this.trtcRoomId = '',
    this.trtcResult,
    this.audioReady = false,
    this.lastError,
    this.lastApiPath,
    this.lastApiStatus,
    this.uiBuildError,
    this.updatedAt,
  });

  final String roomId;
  final bool hasJwt;
  final bool presenceJoined;
  final int presenceCount;
  final bool sseConnected;
  final bool socketConnected;
  final bool trtcEntered;
  final String trtcRoomId;
  final int? trtcResult;
  final bool audioReady;
  final String? lastError;
  final String? lastApiPath;
  final int? lastApiStatus;
  final String? uiBuildError;
  final DateTime? updatedAt;

  bool get isHealthy =>
      roomId.isNotEmpty &&
      hasJwt &&
      presenceJoined &&
      (sseConnected || presenceCount > 0) &&
      uiBuildError == null;

  VoiceRoomDiagnosticState copyWith({
    String? roomId,
    bool? hasJwt,
    bool? presenceJoined,
    int? presenceCount,
    bool? sseConnected,
    bool? socketConnected,
    bool? trtcEntered,
    String? trtcRoomId,
    int? trtcResult,
    bool? audioReady,
    String? lastError,
    bool clearLastError = false,
    String? lastApiPath,
    int? lastApiStatus,
    String? uiBuildError,
    bool clearUiBuildError = false,
    DateTime? updatedAt,
  }) {
    return VoiceRoomDiagnosticState(
      roomId: roomId ?? this.roomId,
      hasJwt: hasJwt ?? this.hasJwt,
      presenceJoined: presenceJoined ?? this.presenceJoined,
      presenceCount: presenceCount ?? this.presenceCount,
      sseConnected: sseConnected ?? this.sseConnected,
      socketConnected: socketConnected ?? this.socketConnected,
      trtcEntered: trtcEntered ?? this.trtcEntered,
      trtcRoomId: trtcRoomId ?? this.trtcRoomId,
      trtcResult: trtcResult ?? this.trtcResult,
      audioReady: audioReady ?? this.audioReady,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      lastApiPath: lastApiPath ?? this.lastApiPath,
      lastApiStatus: lastApiStatus ?? this.lastApiStatus,
      uiBuildError:
          clearUiBuildError ? null : (uiBuildError ?? this.uiBuildError),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get statusSummary {
    if (uiBuildError != null) {
      return 'Arayüz hatası: $uiBuildError';
    }
    if (!hasJwt) return 'Oturum token\'ı yok — giriş gerekli';
    if (!presenceJoined) return 'Odaya katılım bekleniyor…';
    if (!audioReady && !trtcEntered) return 'Ses bağlantısı kuruluyor…';
    if (audioReady || trtcEntered) return 'Bağlı';
    return 'Yükleniyor…';
  }
}

class VoiceRoomDiagnosticNotifier extends Notifier<VoiceRoomDiagnosticState> {
  @override
  VoiceRoomDiagnosticState build() => const VoiceRoomDiagnosticState();

  void resetForRoom(String roomId) {
    state = VoiceRoomDiagnosticState(roomId: roomId, updatedAt: DateTime.now());
  }

  void setJwt({required bool hasJwt}) {
    state = state.copyWith(hasJwt: hasJwt);
  }

  void setPresence({required bool joined, int count = 0}) {
    state = state.copyWith(
      presenceJoined: joined,
      presenceCount: count,
      clearLastError: joined,
    );
  }

  void setSse(bool connected) {
    state = state.copyWith(sseConnected: connected);
  }

  void setSocket(bool connected) {
    state = state.copyWith(socketConnected: connected);
  }

  void setTrtc({
    required String roomId,
    required int result,
    bool entered = true,
  }) {
    state = state.copyWith(
      trtcRoomId: roomId,
      trtcResult: result,
      trtcEntered: entered && result > 0,
      audioReady: entered && result > 0,
    );
  }

  void setAudioReady(bool ready) {
    state = state.copyWith(audioReady: ready);
  }

  void setApi({required String path, int? status}) {
    state = state.copyWith(lastApiPath: path, lastApiStatus: status);
  }

  void setError(String? message) {
    if (message == null || message.isEmpty) {
      state = state.copyWith(clearLastError: true);
      return;
    }
    state = state.copyWith(lastError: message);
  }

  void setUiBuildError(String? message) {
    if (message == null || message.isEmpty) {
      state = state.copyWith(clearUiBuildError: true);
      return;
    }
    state = state.copyWith(uiBuildError: message);
  }
}

final voiceRoomDiagnosticProvider =
    NotifierProvider<VoiceRoomDiagnosticNotifier, VoiceRoomDiagnosticState>(
  VoiceRoomDiagnosticNotifier.new,
);
