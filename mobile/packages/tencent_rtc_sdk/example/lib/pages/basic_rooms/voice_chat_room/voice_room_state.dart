import 'dart:collection';

import 'package:api_example/debug/generate_test_user_sig.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_listener.dart';
import 'package:tencent_rtc_sdk/tx_device_manager.dart';
import 'package:api_example/utils/bidirectional_map.dart';

/// Üretim `ChatPresenceRow` — socket/SSE presence satırı (demo).
class ChatPresenceRow {
  const ChatPresenceRow({
    required this.id,
    this.name = '',
    this.nickname,
    this.avatar,
    this.chatRole,
    this.roleEmoji,
    this.membership,
    this.seatIndex,
    this.isSpeaking = false,
    this.joinedAt,
  });

  factory ChatPresenceRow.fromJson(Map<String, dynamic> json) {
    return ChatPresenceRow(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      nickname: json['nickname']?.toString(),
      avatar: (json['image'] ?? json['avatar'] ?? json['avatarUrl'])?.toString(),
      chatRole: json['chatRole']?.toString(),
      roleEmoji: (json['roleSymbol'] ?? json['roleEmoji'])?.toString(),
      membership: json['membership']?.toString(),
      seatIndex: json['seatIndex'] is int
          ? json['seatIndex'] as int
          : int.tryParse('${json['seatIndex']}'),
      isSpeaking: json['isSpeaking'] == true,
      joinedAt: json['joinedAt'] is int
          ? json['joinedAt'] as int
          : int.tryParse('${json['joinedAt']}'),
    );
  }

  final String id;
  final String name;
  final String? nickname;
  final String? avatar;
  final String? chatRole;
  final String? roleEmoji;
  final String? membership;
  final int? seatIndex;
  final bool isSpeaking;
  final int? joinedAt;
}

class AudioUser {
  final String userId;
  bool isMuted;
  bool isLocalUser;
  bool isSpeaking;

  AudioUser({
    required this.userId,
    this.isMuted = false,
    this.isLocalUser = false,
    this.isSpeaking = false,
  });
}

class ViewManager {
  static const int MAX_ANCHOR_COUNT = 4;

  final BidirectionalMap<String, int> _userViewMap = BidirectionalMap<String, int>();
  final Queue<int> _availableViewKeys = Queue.from(List.generate(MAX_ANCHOR_COUNT, (index) => index));

  bool isViewKeyAvailable(int key) {
    return _userViewMap.containsValue(key);
  }

  /// Sunucu `seatIndex` (1 tabanlı) → görünüm yuvası (0 tabanlı).
  void assignSeatView(String userId, int seatIndex) {
    if (seatIndex < 1 || seatIndex > MAX_ANCHOR_COUNT) {
      releaseView(userId);
      return;
    }
    final viewKey = seatIndex - 1;
    final occupant = getUserIdByViewKey(viewKey);
    if (occupant != null && occupant != userId) {
      releaseView(occupant);
    }
    releaseView(userId);
    _availableViewKeys.remove(viewKey);
    _userViewMap.add(userId, viewKey);
  }

  String? getUserIdByViewKey(int key) {
    return _userViewMap.getKey(key);
  }

  int? allocateView(String userId) {
    if (_availableViewKeys.isEmpty) return null;

    final viewKey = _availableViewKeys.removeFirst();
    _userViewMap.add(userId, viewKey);
    return viewKey;
  }

  void releaseView(String userId) {
    final viewKey = _userViewMap.getValue(userId);
    if (viewKey != null) {
      _userViewMap.remove(userId);
      _availableViewKeys.addFirst(viewKey);
    }
  }

  bool get hasAvailableView => _availableViewKeys.isNotEmpty;

  void clear() {
    _userViewMap.clear();
    _availableViewKeys.clear();
    _availableViewKeys.addAll(List.generate(MAX_ANCHOR_COUNT, (index) => index));
  }
}

class VoiceRoomState extends ChangeNotifier {
  bool _isLocalMicrophoneEnabled = true;
  bool _isLocalSpeakerEnabled = true;
  String? _localUserId;
  int? _roomId;
  bool _isCallActive = false;
  TRTCCloud? _trtcCloud;
  TXDeviceManager? _deviceManager;
  bool _isInitialized = false;
  final Map<String, AudioUser> _audioUsers = {};
  String _statusMessage = 'Initializing...';
  bool _isEnterRoomSuccess = false;
  bool _isAnchor = false;

  final ViewManager _viewManager = ViewManager();

  // Getters
  bool get isLocalMicrophoneEnabled => _isLocalMicrophoneEnabled;
  bool get isLocalSpeakerEnabled => _isLocalSpeakerEnabled;
  String? get localUserId => _localUserId;
  int? get roomId => _roomId;
  bool get isCallActive => _isCallActive;
  List<AudioUser> get audioUsers => _audioUsers.values.toList();
  bool get isInitialized => _isInitialized;
  String get statusMessage => _statusMessage;
  bool get isEnterRoomSuccess => _isEnterRoomSuccess;
  bool get isAnchor => _isAnchor;
  bool get canBecomeAnchor => _viewManager.hasAvailableView;
  ViewManager get viewManager => _viewManager;

  TRTCCloudListener? _listener;

  Future<void> initializeRoom({
    required String userId,
    required int roomId,
  }) async {
    _localUserId = userId;
    _roomId = roomId;
    _isCallActive = true;
    _statusMessage = 'Initializing...';

    await _initializeTRTC();
    notifyListeners();
  }

  Future<void> _initializeTRTC() async {
    if (_trtcCloud == null) {
      _trtcCloud = await TRTCCloud.sharedInstance();
      _deviceManager = _trtcCloud?.getDeviceManager();
      _isInitialized = true;
    }
    _listener ??= _getTRTCCloudListener();
    if (_listener != null) {
      _trtcCloud?.registerListener(_listener!);
    }

    _statusMessage = 'Entering room...';
    _trtcCloud?.enterRoom(TRTCParams(
      sdkAppId: GenerateTestUserSig.sdkAppId,
      userId: _localUserId ?? "",
      roomId: _roomId ?? 123456,
      role: _isAnchor ? TRTCRoleType.anchor : TRTCRoleType.audience,
      userSig: GenerateTestUserSig.genTestSig(_localUserId!)
    ), TRTCAppScene.voiceChatRoom);

    _trtcCloud?.startLocalAudio(TRTCAudioQuality.speech);
    _deviceManager?.setAudioRoute(TXAudioRoute.speakerPhone);
    _trtcCloud?.enableAudioVolumeEvaluation(true, TRTCAudioVolumeEvaluateParams(
      interval: 300,
    ));
  }

  _getTRTCCloudListener() {
    return _listener ??= TRTCCloudListener(
      onError: (errorCode, errorMsg) {
        _statusMessage = 'Error: $errorMsg';
        notifyListeners();
      },
      onEnterRoom: (result) {
        print("TRTCCloudListener onEnterRoom: $result");
        if (result > 0) {
          _statusMessage = 'Room entered successfully';
          _isEnterRoomSuccess = true;
        } else {
          _statusMessage = 'Failed to enter room: $result';
          _isEnterRoomSuccess = false;
        }
        notifyListeners();
      },
      onRemoteUserEnterRoom: (userId) {
        _statusMessage = 'User $userId joined the room';
        notifyListeners();
      },
      onRemoteUserLeaveRoom: (userId, reason) {
        removeAudioUser(userId);
        _statusMessage = 'User $userId left the room';
        notifyListeners();
      },
      onUserAudioAvailable: (userId, available) {
        // Koltuk ataması sunucu snapshot'ından — yalnızca ses akışı izlenir.
        if (available) {
          _ensureAudioUser(userId);
        } else {
          _removeAudioStream(userId);
        }
      },
      onUserVoiceVolume: (userVolumes, totalVolume) {
        for (final userVolume in userVolumes) {
          if (userVolume.userId == "") userVolume.userId = localUserId ?? "";

          print("TRTCCloudListener onUserVoiceVolume: ${userVolume.userId} ${userVolume.volume}");
          if (_audioUsers.containsKey(userVolume.userId)) {
            _audioUsers[userVolume.userId]!.isSpeaking = userVolume.volume > 10;
            notifyListeners();
          }
        }
      },
    );
  }

  Future<void> switchRole() async {
    if (_trtcCloud != null) {
      if (!_isAnchor && !canBecomeAnchor) {
        _statusMessage = 'Room anchor limit reached';
        notifyListeners();
        return;
      }

      _isAnchor = !_isAnchor;
      _trtcCloud?.switchRole(_isAnchor ? TRTCRoleType.anchor : TRTCRoleType.audience);

      if (_isAnchor) {
        _statusMessage = 'Switched to anchor';
        if (_isLocalMicrophoneEnabled) {
          _trtcCloud?.startLocalAudio(TRTCAudioQuality.defaultMode);
          addAudioUser(_localUserId!);
        }
      } else {
        _statusMessage = 'Switched to audience';
        _trtcCloud?.stopLocalAudio();
        _isLocalMicrophoneEnabled = false;
        removeAudioUser(_localUserId!);
      }
      notifyListeners();
    }
  }

  updateLocalMicrophoneState(bool enabled) {
    if (_isLocalMicrophoneEnabled != enabled && _trtcCloud != null && _isAnchor) {
      _isLocalMicrophoneEnabled = enabled;
      if (enabled) {
        _trtcCloud?.startLocalAudio(TRTCAudioQuality.defaultMode);
        addAudioUser(_localUserId!);
      } else {
        _trtcCloud?.stopLocalAudio();
        removeAudioUser(_localUserId!);
      }
      notifyListeners();
    }
  }

  updateLocalSpeakerState(bool enabled) {
    if (_isLocalSpeakerEnabled != enabled && _trtcCloud != null) {
      _isLocalSpeakerEnabled = enabled;
      _deviceManager?.setAudioRoute(
        enabled ? TXAudioRoute.speakerPhone : TXAudioRoute.earpiece,
      );
      notifyListeners();
    }
  }

  void addAudioUser(String userId) {
    _ensureAudioUser(userId);
  }

  void _ensureAudioUser(String userId) {
    if (!_audioUsers.containsKey(userId)) {
      _audioUsers[userId] = AudioUser(
        userId: userId,
        isLocalUser: userId == _localUserId,
      );
      notifyListeners();
    }
  }

  void removeAudioUser(String userId) {
    _removeAudioStream(userId);
    _viewManager.releaseView(userId);
    notifyListeners();
  }

  /// Ses akışı kapandı — koltuk görünümü sunucu snapshot'ında kalır.
  void _removeAudioStream(String userId) {
    if (_audioUsers.containsKey(userId)) {
      _audioUsers.remove(userId);
      notifyListeners();
    }
  }

  /// Sunucu-yetkili koltuk/mikrofon/rol — `roomUsers` / `presenceUpdated` diff.
  void applyPresenceSnapshot(
    List<ChatPresenceRow> previous,
    List<ChatPresenceRow> current,
  ) {
    final prevById = {for (final p in previous) p.id: p};
    final nextIds = current.map((p) => p.id).toSet();

    for (final row in current) {
      final prev = prevById[row.id];
      final seatChanged = prev?.seatIndex != row.seatIndex;
      final roleChanged = prev?.chatRole != row.chatRole;
      final speakingChanged = prev?.isSpeaking != row.isSpeaking;
      if (!seatChanged && !roleChanged && !speakingChanged) continue;

      _syncSeatFromServer(row);
    }

    for (final prev in previous) {
      if (!nextIds.contains(prev.id)) {
        _viewManager.releaseView(prev.id);
        _audioUsers.remove(prev.id);
      }
    }

    notifyListeners();
  }

  void _syncSeatFromServer(ChatPresenceRow row) {
    final seat = row.seatIndex;
    if (seat != null && seat >= 1 && seat <= ViewManager.MAX_ANCHOR_COUNT) {
      _viewManager.assignSeatView(row.id, seat);
      _ensureAudioUser(row.id);
      final user = _audioUsers[row.id];
      if (user != null) {
        user.isSpeaking = row.isSpeaking;
      }
    } else {
      _viewManager.releaseView(row.id);
    }
  }

  exitRoom() {
    _isCallActive = false;
    _audioUsers.clear();
    _viewManager.clear();
    if (_trtcCloud != null) {
      _trtcCloud?.exitRoom();
      _trtcCloud?.enableAudioVolumeEvaluation(false, TRTCAudioVolumeEvaluateParams());
    }
    notifyListeners();
  }

  /// Dış kaynaktan (ör. test köprüsü) presence snapshot uygula.
  void ingestPresenceSnapshot(List<ChatPresenceRow> current) {
    applyPresenceSnapshot(const [], current);
  }

  @override
  void dispose() {
    TRTCCloud.destroySharedInstance();
    super.dispose();
  }
}
