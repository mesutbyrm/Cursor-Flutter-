import 'dart:async';

import '../../../trtc/data/datasources/trtc_remote_datasource.dart';
import '../../../trtc/domain/entities/trtc_credentials.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../data/services/voice_room_debug_log.dart';
import 'voice_trtc_exception.dart';

/// Sesli sohbet — Tencent TRTC (`POST /api/trtc/token`).
class VoiceTrtcEngine {
  VoiceTrtcEngine({TrtcRemoteDataSource? tokenSource})
      : _tokenSource = tokenSource,
        _manager = TrtcRoomManager();

  final TrtcRemoteDataSource? _tokenSource;
  final TrtcRoomManager _manager;

  var _inRoom = false;
  var _micOn = true;
  var _publishMic = false;
  String _roomId = '';
  TrtcCredentials? _lastCredentials;

  TrtcRoomManager get manager => _manager;
  bool get isSupported => _manager.isSupported;
  bool get inChannel => _inRoom;
  bool get micOn => _micOn;
  TrtcCredentials? get lastCredentials => _lastCredentials;

  static Future<bool> requestMicrophonePermission() =>
      TrtcRoomManager.requestPermissions(video: false);

  static String trtcRoomIdFor(String rawRoomId) {
    // Yalnızca geriye dönük yedek — yeni akış backend `trtcRoomId` kullanır.
    final id = rawRoomId.trim();
    if (id.isEmpty) return '';
    if (id.startsWith('voice_room_') ||
        id.startsWith('room_') ||
        id.startsWith('live-')) {
      return id;
    }
    return 'voice_room_$id';
  }

  Future<void> joinVoice(
    String roomId, {
    bool publishMic = true,
    TrtcCredentials? prefetchedCredentials,
    String role = 'audience',
    String? userId,
  }) async {
    if (!isSupported) {
      throw const VoiceTrtcException(
        'TRTC yalnızca Android ve iOS cihazlarda desteklenir.',
        phase: 'platform',
      );
    }

    final rawRoomId = roomId.trim();
    if (rawRoomId.isEmpty && prefetchedCredentials == null) {
      throw const VoiceTrtcException(
        'Oda kimliği boş — ses bağlantısı kurulamadı.',
        phase: 'validate',
      );
    }

    final trtcRoom = prefetchedCredentials?.effectiveStrRoomId.isNotEmpty == true
        ? prefetchedCredentials!.effectiveStrRoomId
        : rawRoomId;
    VoiceRoomDebugLog.log('audio.trtc.prepare', {
      'roomId': rawRoomId,
      'trtcRoom': trtcRoom,
      'publishMic': publishMic,
      'fromBackend': prefetchedCredentials != null,
    });

    try {
      final micOk = await requestMicrophonePermission();
      if (!micOk) {
        throw const VoiceTrtcException(
          'Mikrofon izni verilmedi. Ayarlardan mikrofonu açıp tekrar deneyin.',
          phase: 'permission',
        );
      }

      if (_inRoom && _roomId == trtcRoom) {
        await setMicEnabled(publishMic);
        return;
      }

      if (_inRoom) {
        await leave();
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      final effectiveRole = publishMic ? 'host' : role;
      TrtcCredentials? credentials = prefetchedCredentials;
      final tokenSource = _tokenSource;
      if (credentials == null && tokenSource != null) {
        credentials = await tokenSource.fetchToken(
          roomId: rawRoomId,
          role: effectiveRole,
          userId: userId,
        );
      }

      if (credentials == null || !credentials.isValid) {
        throw const VoiceTrtcException(
          'TRTC token geçersiz veya süresi dolmuş. Odaya tekrar girin.',
          phase: 'token',
        );
      }

      VoiceRoomDebugLog.log('audio.trtc.token', {
        'roomId': credentials.effectiveStrRoomId,
        'userId': credentials.userId,
        'sdkAppId': credentials.sdkAppId,
        'numericUid': credentials.numericUid,
      });

      await _manager.join(
        credentials: credentials,
        isHost: publishMic,
        audioOnly: true,
      );

      _inRoom = true;
      _roomId = credentials.effectiveStrRoomId;
      _lastCredentials = credentials;
      _publishMic = publishMic;
      if (!publishMic) {
        _manager.setMicEnabled(false);
        _micOn = false;
      } else {
        _micOn = true;
      }

      VoiceRoomDebugLog.log('audio.trtc.joined', {
        'roomId': trtcRoom,
        'mic': publishMic,
      });
    } on VoiceTrtcException {
      rethrow;
    } catch (e, st) {
      VoiceRoomDebugLog.log('audio.trtc.join.fail', {
        'roomId': rawRoomId,
        'error': e.toString(),
        'stack': st.toString(),
      });
      throw VoiceTrtcException(
        'Ses bağlantısı kurulamadı: $e',
        cause: e,
        stackTrace: st,
        phase: 'joinVoice',
      );
    }
  }

  Future<void> setMicEnabled(bool enabled) async {
    if (!_inRoom) return;
    if (enabled == _micOn && enabled == _publishMic) return;

    if (enabled && !_publishMic) {
      final tokenSource = _tokenSource;
      final roomId = _roomId;
      if (tokenSource != null && roomId.isNotEmpty) {
        final cred = await tokenSource.fetchToken(roomId: roomId, role: 'host');
        await _manager.leave();
        await _manager.join(
          credentials: cred,
          isHost: true,
          audioOnly: true,
        );
        _lastCredentials = cred;
        _publishMic = true;
        _micOn = true;
        return;
      }
    }

    _manager.setMicEnabled(enabled);
    _micOn = enabled;
    if (!enabled) {
      _publishMic = false;
      _manager.stopLocalAudioPublish();
    }
  }

  void setRemoteAudioMuted(bool muted) {
    _manager.setAllRemoteAudioMuted(muted);
  }

  Future<void> leave() async {
    try {
      await _manager.leave();
    } catch (_) {}
    _inRoom = false;
    _micOn = false;
    _publishMic = false;
    _roomId = '';
    _lastCredentials = null;
  }

  Future<void> dispose() async {
    await leave();
    _manager.dispose();
  }
}
