import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_listener.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_video_view.dart';
import 'package:tencent_rtc_sdk/tx_audio_effect_manager.dart';
import 'package:tencent_rtc_sdk/tx_device_manager.dart';

import '../../voice_hub/data/services/voice_room_debug_log.dart';
import '../domain/entities/trtc_credentials.dart';
import '../domain/voice_audio_settings.dart';
import 'trtc_operation_gate.dart';

/// Tencent TRTC oda oturumu — canlı yayın ve sesli sohbet.
class TrtcRoomManager {
  /// Tek `TRTCCloud.sharedInstance()` — eşzamanlı çoklu manager oturumu engelle.
  static TrtcRoomManager? _activeSession;
  final _opGate = TrtcOperationGate();
  String? _joinedStrRoomId;

  TRTCCloud? _cloud;
  TXDeviceManager? _device;
  TRTCCloudListener? _listener;
  Completer<int>? _enterRoomCompleter;
  Completer<void>? _exitRoomCompleter;

  bool _inRoom = false;
  bool _previewOnly = false;
  bool _micOn = true;
  bool _cameraOn = true;
  bool _isHost = false;
  bool _twoWayVideo = false;
  bool _audioOnly = false;
  bool _notifiersDisposed = false;
  String? _localUserId;

  String? remoteAnchorUserId;
  final ValueNotifier<String?> remoteAnchorUserIdNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<bool> remoteVideoAvailable = ValueNotifier(false);
  /// Katılımcı bazlı uzak video durumu — yerel kamera ile karıştırılmaz.
  final ValueNotifier<Map<String, bool>> remoteVideoByUser =
      ValueNotifier<Map<String, bool>>({});
  /// Katılımcı bazlı uzak ses durumu — yerel mikrofon ile karıştırılmaz.
  final ValueNotifier<Map<String, bool>> remoteAudioByUser =
      ValueNotifier<Map<String, bool>>({});

  /// Şu an konuşan katılımcılar (TRTC ses seviyesi) — yerel kullanıcı için
  /// [localSpeakingKey] kullanılır. Çoklu yayın ızgarasında vurgu için.
  static const localSpeakingKey = '__local__';
  final ValueNotifier<Set<String>> speakingUsersNotifier =
      ValueNotifier<Set<String>>(const {});

  void _updateSpeaking(List<TRTCVolumeInfo> volumes) {
    if (_notifiersDisposed) return;
    final next = <String>{
      for (final v in volumes)
        if (v.volume >= 15) v.userId.isEmpty ? localSpeakingKey : v.userId,
    };
    final cur = speakingUsersNotifier.value;
    if (next.length == cur.length && next.containsAll(cur)) return;
    speakingUsersNotifier.value = next;
  }

  final Map<String, int> _remoteViewBindings = {};
  String? _expectedAnchorUserId;

  /// Bağlantı koptuğunda çağrılır (yeniden bağlanma koordinatörde).
  VoidCallback? onConnectionLost;

  /// Sesli oda — TRTC volume (userId boş = yerel kullanıcı).
  void Function(List<TRTCVolumeInfo> userVolumes, int totalVolume)?
      onUserVoiceVolume;

  final ValueNotifier<int?> networkQuality = ValueNotifier<int?>(null);

  bool get isSupported => !kIsWeb;
  bool get inRoom => _inRoom;
  /// Agora uyumluluk — `inChannel` yerine.
  bool get inChannel => _inRoom;
  /// Son başarılı `enterRoom` strRoomId — token `effectiveStrRoomId`.
  String? get joinedStrRoomId => _joinedStrRoomId;
  bool get operationInFlight => _opGate.isBusy;

  final ValueNotifier<List<String>> remoteUserIdsNotifier =
      ValueNotifier<List<String>>([]);
  final Set<String> _remoteUserIds = {};
  bool get micOn => _micOn;
  bool get cameraOn => _cameraOn;

  void _trtcLog(String event, [Map<String, Object?> fields = const {}]) {
    _logTrtc(event, fields);
  }

  static void _logTrtc(String event, [Map<String, Object?> fields = const {}]) {
    if (!kDebugMode) return;
    final safe = Map<String, Object?>.from(fields)
      ..remove('userSig')
      ..remove('token')
      ..remove('accessToken');
    debugPrint('[TRTC] $event $safe');
  }

  /// Mikrofon (+ isteğe bağlı kamera) izni. Zaten verilmişse pencere açılmaz.
  /// İzinler ilk açılışta [MediaPermissionBootstrap] ile bir kez istenir;
  /// burada yalnızca yayın/mikrofon gerçekten açılacaksa tekrar sorulur.
  /// Kalıcı reddedilmişse kullanıcı her girişte Ayarlar'a atılmaz — çağıran
  /// taraf mesaj gösterir.
  static Future<bool> requestPermissions({required bool video}) async {
    if (kIsWeb) return false;
    try {
      if (!await _ensureGranted(Permission.microphone)) return false;
      if (video && !await _ensureGranted(Permission.camera)) return false;
      return true;
    } on MissingPluginException {
      _logTrtc('permission_plugin_missing');
      return false;
    } catch (e) {
      _logTrtc('permission_error', {'error': e.runtimeType.toString()});
      return false;
    }
  }

  static Future<bool> _ensureGranted(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied || status.isRestricted) return false;
    final result = await permission.request();
    return result.isGranted || result.isLimited;
  }

  /// Önizleme — kanala girmeden kamera (yayın hazırlığı).
  Future<void> startPreviewOnly() async {
    if (!isSupported) return;
    final ok = await requestPermissions(video: true);
    if (!ok) throw StateError('Kamera izni gerekli');

    _cloud ??= await TRTCCloud.sharedInstance();
    _device ??= _cloud!.getDeviceManager();
    _previewOnly = true;
    _isHost = true;
    _cameraOn = true;
    _configureAudioProcessing();
  }

  /// Önizlemeden yayın odasına geçerken motoru bırak.
  Future<void> shutdownForHandoff() async {
    if (_previewOnly) {
      _cloud?.stopLocalPreview();
      _previewOnly = false;
    }
    await leave();
  }

  void muteAllRemoteAudioStreams(bool mute) => setAllRemoteAudioMuted(mute);

  Future<void> join({
    required TrtcCredentials credentials,
    required bool isHost,
    bool audioOnly = false,
    String? expectedAnchorUserId,
    bool twoWayVideo = false,
    bool? publishLocal,
  }) {
    return _opGate.run(
      () => _joinUnlocked(
        credentials: credentials,
        isHost: isHost,
        audioOnly: audioOnly,
        expectedAnchorUserId: expectedAnchorUserId,
        twoWayVideo: twoWayVideo,
        publishLocal: publishLocal,
      ),
    );
  }

  Future<void> _joinUnlocked({
    required TrtcCredentials credentials,
    required bool isHost,
    bool audioOnly = false,
    String? expectedAnchorUserId,
    bool twoWayVideo = false,
    bool? publishLocal,
  }) async {
    if (!isSupported) {
      throw StateError('TRTC yalnızca Android/iOS üzerinde desteklenir');
    }

    final roomId = credentials.effectiveStrRoomId;
    if (roomId.isEmpty) {
      throw StateError('TRTC oda kimliği boş — yayına bağlanılamadı');
    }

    try {
      _trtcLog('initialize', {'roomId': roomId});
      await TRTCCloud.sharedInstance();
    } catch (e) {
      throw StateError(
        'Tencent RTC bu cihazda başlatılamadı. Lütfen uygulamayı yeniden başlatın.',
      );
    }

    // İzleyici/dinleyici yayın göndermez; mikrofon/kamera izni gerekmez.
    // Önceden her girişte izin soruluyor, reddeden izleyici odaya giremiyordu.
    final publishes = isHost || twoWayVideo || (publishLocal ?? false);
    if (publishes) {
      final ok = await requestPermissions(video: !audioOnly);
      if (!ok) {
        throw StateError(
          'Mikrofon veya kamera izni verilmedi. Ayarlar > Uygulamalar > '
          'Canlifal > İzinler bölümünden açabilirsiniz.',
        );
      }
    }

    if (_inRoom) {
      await _leaveUnlocked();
    }

    final other = _activeSession;
    if (other != null && other != this && other._inRoom) {
      await other.leave();
    }

    _previewOnly = false;
    _audioOnly = audioOnly;

    _cloud ??= await TRTCCloud.sharedInstance();
    _device ??= _cloud!.getDeviceManager();
    // `forceSilenceNow` önceki çıkışta uzak sesi kapatmış olabilir: yeni
    // oturum duyabilsin.
    _cloud!.muteAllRemoteAudio(false);
    _isHost = isHost;
    _twoWayVideo = twoWayVideo;
    _localUserId = credentials.userId.trim();
    _expectedAnchorUserId =
        expectedAnchorUserId?.trim().isNotEmpty == true
            ? expectedAnchorUserId!.trim()
            : null;

    _enterRoomCompleter = Completer<int>();
    if (_cloud != null && _listener != null) {
      _cloud!.unRegisterListener(_listener!);
    }
    _listener = TRTCCloudListener(
      onError: (code, msg) =>
          _trtcLog('error', {'code': code, 'message': msg}),
      onWarning: (code, msg) =>
          _trtcLog('warning', {'code': code, 'message': msg}),
      onEnterRoom: (result) {
        _inRoom = result > 0;
        VoiceRoomDebugLog.log('audio.trtc.enter_room', {
          'result': result,
          'room': roomId,
          'host': _isHost,
          'audioOnly': audioOnly,
        });
        _trtcLog('enter_room', {
          'result': result,
          'roomId': roomId,
          'host': _isHost,
        });
        if (result > 0) {
          _trtcLog('join_success', {'roomId': roomId, 'result': result});
        }
        final c = _enterRoomCompleter;
        if (c != null && !c.isCompleted) c.complete(result);
      },
      onRemoteUserEnterRoom: (userId) {
        _trtcLog('remote_enter', {'userId': userId});
        if (userId == _localUserId) return;
        _trtcLog('remote_user_joined', {'userId': userId});
        _trackRemoteUser(userId, joined: true);
        if (_twoWayVideo) {
          _setRemoteAnchor(userId);
          _unmuteRemoteAudio(userId);
        }
        _enforceLocalRemoteMute(userId);
      },
      onRemoteUserLeaveRoom: (userId, _) {
        _trtcLog('remote_leave', {'userId': userId});
        _trackRemoteUser(userId, joined: false);
        stopRemoteView(userId);
        final videoMap = Map<String, bool>.from(remoteVideoByUser.value);
        videoMap.remove(userId);
        remoteVideoByUser.value = videoMap;
        final audioMap = Map<String, bool>.from(remoteAudioByUser.value);
        audioMap.remove(userId);
        remoteAudioByUser.value = audioMap;
        if (remoteAnchorUserId == userId) {
          _clearRemoteAnchor();
        }
      },
      onExitRoom: (reason) {
        _trtcLog('exit_room', {'reason': reason});
        _inRoom = false;
        final c = _exitRoomCompleter;
        if (c != null && !c.isCompleted) c.complete();
      },
      onConnectionLost: () {
        _trtcLog('connection_lost');
        onConnectionLost?.call();
      },
      onNetworkQuality: (local, remote) {
        networkQuality.value = local.quality.index;
      },
      onUserVideoAvailable: (userId, available) {
        if (_audioOnly) {
          if (available && userId != _localUserId) {
            _cloud?.stopRemoteView(userId, TRTCVideoStreamType.big);
          }
          return;
        }
        _trtcLog('user_video', {'userId': userId, 'available': available});
        if (userId == _localUserId) return;
        _trtcLog('remote_video', {'userId': userId, 'available': available});
        _setRemoteVideoState(userId, available);
        if (!_twoWayVideo && _isHost) return;
        if (available) {
          _setRemoteAnchor(userId);
          _tryBindPendingRemoteView(userId);
        } else if (remoteAnchorUserId == userId) {
          // Kısa unavailable = encoder boşluğu; oda kopuşu değil.
          // 1:1 görüşmede view'i sökmek donma + sahte rejoin yaratır.
          remoteVideoAvailable.value = false;
          if (!_twoWayVideo) {
            stopRemoteView(userId);
            _clearRemoteAnchor();
          }
        }
      },
      onUserAudioAvailable: (userId, available) {
        _trtcLog('user_audio', {'userId': userId, 'available': available});
        if (userId == _localUserId) return;
        _trtcLog('remote_audio', {'userId': userId, 'available': available});
        _setRemoteAudioState(userId, available);
        if (!_twoWayVideo && _isHost) {
          _enforceLocalRemoteMute(userId);
          return;
        }
        if (available) {
          _unmuteRemoteAudio(userId);
        } else {
          _cloud?.muteRemoteAudio(userId, true);
        }
      },
      onUserVoiceVolume: (userVolumes, totalVolume) {
        _updateSpeaking(userVolumes);
        onUserVoiceVolume?.call(userVolumes, totalVolume);
      },
    );
    _cloud!.registerListener(_listener!);
    _configureAudioProcessing();

    // Canlı yayın izleyicisi: otomatik ses/video alımı (enterRoom öncesi).
    if (audioOnly) {
      _cloud!.setDefaultStreamRecvMode(true, false);
    } else {
      _cloud!.setDefaultStreamRecvMode(true, true);
    }

    final publishAsAnchor =
        publishLocal ?? (isHost || twoWayVideo);
    final params = TRTCParams(
      sdkAppId: credentials.sdkAppId,
      userId: credentials.userId,
      userSig: credentials.userSig,
      roomId: 0,
      strRoomId: roomId,
      role: publishAsAnchor ? TRTCRoleType.anchor : TRTCRoleType.audience,
    );

    // İki yönlü görüşme: videoCall; tek yönlü yayın: live.
    final scene = audioOnly
        ? TRTCAppScene.voiceChatRoom
        : (twoWayVideo ? TRTCAppScene.videoCall : TRTCAppScene.live);
    _trtcLog('join_start', {
      'roomId': roomId,
      'userId': credentials.userId,
      'sdkAppId': credentials.sdkAppId,
      'audioOnly': audioOnly,
      'role': publishAsAnchor ? 'anchor' : 'audience',
    });

    // QoS — akıcılık (düşük gecikme) önceliği her sahnede geçerli olmalı.
    // Önceden yalnızca video yayıncısına uygulanıyordu; sesli oda ve izleyici
    // tarafı SDK varsayılanı olan netlik önceliğinde kalıp dar bantta
    // tamponlama yüzünden ses/görüntü gecikmesi biriktiriyordu.
    _cloud!.setNetworkQosParam(
      TRTCNetworkQosParam(preference: TRTCVideoQosPreference.smooth),
    );

    // Hardware encoding — T+5s freeze düzeltme: enterRoom öncesi encoder parametreleri.
    if (!audioOnly && publishAsAnchor) {
      final encParam = TRTCVideoEncParam(
        videoResolution: TRTCVideoResolution.res_640_360,
        videoResolutionMode: TRTCVideoResolutionMode.portrait,
        videoFps: 24,
        videoBitrate: 800,
        minVideoBitrate: 480,
        enableAdjustRes: true,
      );
      _cloud!.setVideoEncoderParam(encParam);
    }

    await VoiceAudioSettingsStore.ensureLoaded();
    _cloud!.enterRoom(params, scene);

    final enterResult = await _enterRoomCompleter!.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => -1,
    );
    _enterRoomCompleter = null;
    if (enterResult <= 0) {
      throw StateError(
        'Canlı odaya bağlanılamadı (kod: $enterResult). İnterneti kontrol edin.',
      );
    }

    _activeSession = this;
    _joinedStrRoomId = roomId;

    if (audioOnly) {
      _startLocalAudio();
      _device?.setAudioRoute(TXAudioRoute.speakerPhone);
      _micOn = true;
      _trtcLog('local_audio', {'roomId': roomId, 'enabled': true});
    } else if (publishAsAnchor) {
      _startLocalAudio();
      _cloud!.muteLocalVideo(TRTCVideoStreamType.big, false);
      // Yerel önizleme yalnızca TrtcLocalVideoView.onViewCreated ile bağlanır.
      // viewId=0 kullanımı uzak tam ekran yüzeyini ele geçirip kamera flip-flop yapar.
      _micOn = true;
      _cameraOn = true;
      _device?.setAudioRoute(TXAudioRoute.speakerPhone);
      _trtcLog('local_audio', {'roomId': roomId, 'enabled': true});
      _trtcLog('local_video', {'roomId': roomId, 'enabled': true});
    } else {
      _device?.setAudioRoute(TXAudioRoute.speakerPhone);
    }
  }

  void _setRemoteVideoState(String userId, bool available) {
    if (userId.isEmpty || userId == _localUserId) return;
    final next = Map<String, bool>.from(remoteVideoByUser.value);
    if (available) {
      next[userId] = true;
    } else {
      next.remove(userId);
    }
    remoteVideoByUser.value = next;
  }

  void _setRemoteAudioState(String userId, bool available) {
    if (userId.isEmpty || userId == _localUserId) return;
    final next = Map<String, bool>.from(remoteAudioByUser.value);
    if (available) {
      next[userId] = true;
    } else {
      next.remove(userId);
    }
    remoteAudioByUser.value = next;
  }

  void _trackRemoteUser(String userId, {required bool joined}) {
    if (userId.isEmpty || userId == _localUserId) return;
    if (joined) {
      _remoteUserIds.add(userId);
    } else {
      _remoteUserIds.remove(userId);
    }
    remoteUserIdsNotifier.value = _remoteUserIds.toList(growable: false);
  }

  /// Yayın kalitesi — TRTC video encoder parametreleri.
  Future<void> setEncoderParams({
    required int width,
    required int height,
    required int bitrateKbps,
    required int fps,
  }) async {
    if (_cloud == null) return;
    final resolution = _resolveVideoResolution(width, height);
    final bitrate = bitrateKbps > 0 ? bitrateKbps : _defaultBitrateFor(resolution);
    final param = TRTCVideoEncParam(
      videoResolution: resolution,
      videoResolutionMode: TRTCVideoResolutionMode.portrait,
      videoFps: fps.clamp(15, 30),
      videoBitrate: bitrate,
      minVideoBitrate: (bitrate * 0.6).round(),
      enableAdjustRes: true,
    );
    _cloud!.setVideoEncoderParam(param);
    _cloud!.setNetworkQosParam(
      TRTCNetworkQosParam(preference: TRTCVideoQosPreference.smooth),
    );
    _trtcLog('encoder', {
      'width': width,
      'height': height,
      'bitrateKbps': bitrate,
      'fps': fps,
    });
  }

  TRTCVideoResolution _resolveVideoResolution(int width, int height) {
    final maxSide = width > height ? width : height;
    if (maxSide >= 1920) return TRTCVideoResolution.res_1920_1080;
    if (maxSide >= 1280) return TRTCVideoResolution.res_1280_720;
    if (maxSide >= 960) return TRTCVideoResolution.res_960_540;
    return TRTCVideoResolution.res_640_360;
  }

  int _defaultBitrateFor(TRTCVideoResolution resolution) {
    return switch (resolution) {
      TRTCVideoResolution.res_1920_1080 => 2500,
      TRTCVideoResolution.res_1280_720 => 1500,
      TRTCVideoResolution.res_960_540 => 1000,
      _ => 600,
    };
  }

  /// Odalar arası PK ses köprüsü (TRTC cross-room): çağıran sahip, karşı odanın
  /// sahibini arar; iki odanın dinleyicileri karşı sahibin sesini de duyar.
  /// Sonuç `onConnectOtherRoom` ile bildirilir; hata sessizce loglanır.
  void connectOtherRoom({required String strRoomId, required String userId}) {
    if (strRoomId.trim().isEmpty || userId.trim().isEmpty) return;
    try {
      _cloud?.connectOtherRoom(
        jsonEncode({'strRoomId': strRoomId.trim(), 'userId': userId.trim()}),
      );
      _trtcLog('connect_other_room', {'room': strRoomId, 'user': userId});
    } catch (e) {
      _trtcLog('connect_other_room_error', {'error': '$e'});
    }
  }

  void disconnectOtherRoom() {
    try {
      _cloud?.disconnectOtherRoom();
      _trtcLog('disconnect_other_room', const {});
    } catch (_) {}
  }

  void muteRemoteAudio(String userId, bool mute) {
    if (!mute) {
      _unmuteRemoteAudio(userId);
      return;
    }
    _cloud?.muteRemoteAudio(userId, true);
  }

  /// Yalnızca BU cihazda sesi kapatılan uzak kullanıcılar (ör. PK'da karşı takım).
  ///
  /// TRTC `muteRemoteAudio` yerel oynatmayı keser; kullanıcının mikrofonu,
  /// diğer dinleyiciler ve backend etkilenmez. Otomatik "ses geldi → aç"
  /// mantığı ve kulaklık (tümünü aç) bu kümeyi ezmez.
  final Set<String> _locallyMutedRemote = <String>{};

  Set<String> get locallyMutedRemoteUsers => Set.unmodifiable(_locallyMutedRemote);

  void setLocallyMutedRemoteUsers(Set<String> userIds) {
    final next = userIds.where((id) => id.trim().isNotEmpty).toSet();
    final prev = Set<String>.of(_locallyMutedRemote);
    _locallyMutedRemote
      ..clear()
      ..addAll(next);
    for (final id in next) {
      if (!prev.contains(id)) _cloud?.muteRemoteAudio(id, true);
    }
    for (final id in prev) {
      if (!next.contains(id)) _cloud?.muteRemoteAudio(id, false);
    }
    _trtcLog('local_mute_remote', {'users': next.length});
  }

  /// Yerel susturma listesindeyse sessiz tut; değilse sesi aç.
  void _unmuteRemoteAudio(String userId) {
    if (_locallyMutedRemote.contains(userId)) {
      _cloud?.muteRemoteAudio(userId, true);
      return;
    }
    _cloud?.muteRemoteAudio(userId, false);
  }

  void _enforceLocalRemoteMute(String userId) {
    if (_locallyMutedRemote.contains(userId)) {
      _cloud?.muteRemoteAudio(userId, true);
    }
  }

  void _configureAudioProcessing() {
    if (_cloud == null) return;
    // Sesli oda: konuşma halkası TRTC volume ile (SSE yedek kalır).
    _cloud!.enableAudioVolumeEvaluation(
      true,
      TRTCAudioVolumeEvaluateParams(interval: _audioOnly ? 200 : 300),
    );
    _device?.setAudioRoute(TXAudioRoute.speakerPhone);
  }

  void _setRemoteAnchor(String userId) {
    if (userId.isEmpty || userId == _localUserId) return;
    if (_expectedAnchorUserId != null && userId != _expectedAnchorUserId) {
      return;
    }
    remoteAnchorUserId = userId;
    remoteAnchorUserIdNotifier.value = userId;
    remoteVideoAvailable.value = true;
  }

  void _clearRemoteAnchor() {
    remoteAnchorUserId = null;
    remoteAnchorUserIdNotifier.value = null;
    remoteVideoAvailable.value = false;
  }

  void _tryBindPendingRemoteView(String userId) {
    final viewId = _remoteViewBindings[userId];
    if (viewId != null && _cloud != null) {
      _cloud!.startRemoteView(userId, TRTCVideoStreamType.big, viewId);
    }
  }

  void startLocalPreview(int viewId) {
    if (_audioOnly) return;
    if (_cloud == null) return;
    if (!_inRoom && !_previewOnly) return;
    _cloud!.muteLocalVideo(TRTCVideoStreamType.big, false);
    _cloud!.startLocalPreview(true, viewId);
    _cameraOn = true;
    _trtcLog('local_video', {'viewId': viewId, 'enabled': true});
  }

  void stopLocalPreview() {
    _cloud?.stopLocalPreview();
    _cloud?.muteLocalVideo(TRTCVideoStreamType.big, true);
    _cameraOn = false;
    _trtcLog('local_video', {'enabled': false});
  }

  void startRemoteView(String userId, int viewId) {
    if (_audioOnly) return;
    if (_cloud == null || !_inRoom) return;
    _remoteViewBindings[userId] = viewId;
    _cloud!.startRemoteView(userId, TRTCVideoStreamType.big, viewId);
    _unmuteRemoteAudio(userId);
    _trtcLog('remote_video', {'userId': userId, 'viewId': viewId, 'enabled': true});
    _trtcLog('remote_audio', {'userId': userId, 'muted': false});
  }

  void stopRemoteView(String userId) {
    _cloud?.stopRemoteView(userId, TRTCVideoStreamType.big);
    _trtcLog('remote_video', {'userId': userId, 'enabled': false});
    _remoteViewBindings.remove(userId);
  }

  /// Uzak render takıldığında GÜVENLİ kurtarma — odadan çıkış / yeniden giriş
  /// YOK. Yalnızca mevcut view binding'i için `stopRemoteView` + `startRemoteView`
  /// tekrar çağrılır (donmuş yüzeyi yeniden bağlar). Binding yoksa no-op.
  /// Not: 1:1 falcı görüşmesinde T+5s render takılması için yedek; alias-drift
  /// yeniden giriş bug'ını geri getirmez.
  bool resubscribeRemoteView(String userId) {
    if (_audioOnly) return false;
    if (_cloud == null || !_inRoom) return false;
    final viewId = _remoteViewBindings[userId];
    if (viewId == null) return false;
    _cloud!.stopRemoteView(userId, TRTCVideoStreamType.big);
    _cloud!.startRemoteView(userId, TRTCVideoStreamType.big, viewId);
    _unmuteRemoteAudio(userId);
    _trtcLog('remote_video_resubscribe', {'userId': userId, 'viewId': viewId});
    return true;
  }

  void _startLocalAudio() {
    final cloud = _cloud;
    if (cloud == null) return;
    final s = VoiceAudioSettingsStore.current;
    cloud.startLocalAudio(s.quality);
    _applyVoiceEffects(s);
  }

  void _applyVoiceEffects(VoiceAudioSettings s) {
    final cloud = _cloud;
    if (cloud == null) return;
    cloud.setAudioCaptureVolume(s.captureVolume);
    final fx = cloud.getAudioEffectManager();
    fx.setVoiceReverbType(s.reverb);
    fx.setVoiceChangerType(s.changer);
    fx.enableVoiceEarMonitor(s.earMonitor);
    _trtcLog('voice_effects', {
      'quality': s.quality.name,
      'reverb': s.reverb.name,
      'changer': s.changer.name,
      'volume': s.captureVolume,
      'ear': s.earMonitor,
    });
  }

  /// Ayarlar ekranından: efekt/ses seviyesi açık oturuma anında uygulanır;
  /// kalite değişikliği bir sonraki mikrofon açılışında geçerli olur.
  static void applyVoiceSettingsToActiveSession() {
    final session = _activeSession;
    if (session == null || !session._inRoom || !session._micOn) return;
    session._applyVoiceEffects(VoiceAudioSettingsStore.current);
  }

  bool _micLockedByHost = false;
  bool _cameraLockedByHost = false;

  /// Yayıncı misafirin mikrofon/kamerasını kapattığında kilit konur; kilitliyken
  /// yerel açma istekleri yok sayılır. Kilit koymak ilgili aygıtı da kapatır.
  void setHostMediaLock({bool? mic, bool? camera}) {
    if (mic != null) {
      _micLockedByHost = mic;
      if (mic) setMicEnabled(false);
    }
    if (camera != null) {
      _cameraLockedByHost = camera;
      if (camera) setCameraEnabled(false);
    }
  }

  bool get micLockedByHost => _micLockedByHost;
  bool get cameraLockedByHost => _cameraLockedByHost;

  void setMicEnabled(bool enabled) {
    if (enabled && _micLockedByHost) return;
    if (!_inRoom && !_previewOnly) return;
    if (enabled) {
      _startLocalAudio();
      _cloud?.muteLocalAudio(false);
    } else {
      _cloud?.muteLocalAudio(true);
      _cloud?.stopLocalAudio();
    }
    _micOn = enabled;
    _trtcLog('mute_unmute', {'micEnabled': enabled, 'stoppedPublish': !enabled});
  }

  /// Koltuk kaybında ses yayınını tamamen durdur.
  void stopLocalAudioPublish() {
    if (_cloud == null) return;
    _cloud!.muteLocalAudio(true);
    _cloud!.stopLocalAudio();
    _micOn = false;
    _trtcLog('local_audio_stopped', const {});
  }

  void setCameraEnabled(bool enabled) {
    if (enabled && _cameraLockedByHost) return;
    if (_cloud == null) return;
    if (!_inRoom && !_previewOnly) return;
    if (!_isHost && !_twoWayVideo && !_previewOnly) return;
    _cloud!.muteLocalVideo(TRTCVideoStreamType.big, !enabled);
    _cameraOn = enabled;
    _trtcLog('camera_on_off', {'cameraEnabled': enabled});
  }

  void setAllRemoteAudioMuted(bool mute) {
    _cloud?.muteAllRemoteAudio(mute);
    if (!mute) {
      // "Tümünü aç" yerel susturmayı bozmasın.
      for (final id in _locallyMutedRemote) {
        _cloud?.muteRemoteAudio(id, true);
      }
    }
  }

  void switchCamera() {
    _device?.switchCamera(_cameraOn);
  }

  Future<void> leave() {
    // Kapıdaki bir işlem (join/reconnect) takılsa bile ses ANINDA kesilir.
    forceSilenceNow();
    return _opGate.run(_leaveUnlocked);
  }

  /// İşlem kapısını beklemeden yerel yayını ve tüm uzak sesleri keser.
  /// Odadan çıkarken / koltuktan inerken kullanıcı hâlâ duyuyor ve duyuluyordu.
  void forceSilenceNow() {
    final c = _cloud;
    if (c == null) return;
    try {
      c.muteAllRemoteAudio(true);
    } catch (_) {}
    try {
      c.stopLocalAudio();
    } catch (_) {}
    try {
      c.muteLocalAudio(true);
    } catch (_) {}
    _micOn = false;
  }

  Future<void> _leaveUnlocked() async {
    _trtcLog('leave', {'inRoom': _inRoom});
    stopPublishedMusic();
    onConnectionLost = null;
    networkQuality.value = null;
    remoteVideoAvailable.value = false;
    _expectedAnchorUserId = null;
    _clearRemoteAnchor();
    _remoteViewBindings.clear();
    _remoteUserIds.clear();
    _locallyMutedRemote.clear();
    remoteUserIdsNotifier.value = const [];
    remoteVideoByUser.value = const {};
    remoteAudioByUser.value = const {};
    if (_cloud != null) {
      _cloud!.stopLocalPreview();
      _cloud!.stopLocalAudio();
      if (_inRoom) {
        _exitRoomCompleter = Completer<void>();
        _cloud!.exitRoom();
        try {
          await _exitRoomCompleter!.future.timeout(
            const Duration(seconds: 2),
            onTimeout: () {},
          );
        } catch (_) {}
        _exitRoomCompleter = null;
      } else {
        // `_inRoom` henüz true olmadan (enterRoom sürerken) çıkılırsa kanal
        // açık kalıyordu; yine de çıkış komutu gönder.
        try {
          _cloud!.exitRoom();
        } catch (_) {}
      }
      if (_listener != null) {
        _cloud!.unRegisterListener(_listener!);
        _listener = null;
      }
    }
    _inRoom = false;
    _joinedStrRoomId = null;
    _previewOnly = false;
    _audioOnly = false;
    _isHost = false;
    _twoWayVideo = false;
    _localUserId = null;
    _micOn = false;
    _cameraOn = false;
    if (_activeSession == this) {
      _activeSession = null;
    }
  }

  static const int voiceRoomMusicId = 88001;
  var _publishedMusicPlaying = false;

  /// DJ / !istek müziğini TRTC uplink'e karıştır (uzak dinleyiciler duyar).
  Future<void> playPublishedMusic(
    String url, {
    int startMs = 0,
    int publishVolume = 80,
  }) async {
    if (!isSupported || _cloud == null || url.trim().isEmpty) return;
    final path = url.trim();
    stopPublishedMusic();
    final effect = _cloud!.getAudioEffectManager();
    effect.startPlayMusic(
      AudioMusicParam(
        id: voiceRoomMusicId,
        path: path,
        publish: true,
        loopCount: 0,
        startTimeMS: startMs.clamp(0, 1 << 30),
      ),
    );
    effect.setMusicPublishVolume(voiceRoomMusicId, publishVolume);
    _publishedMusicPlaying = true;
    VoiceRoomDebugLog.log('trtc.music.publish.start', {
      'url': path.length > 64 ? '${path.substring(0, 64)}…' : path,
      'startMs': startMs,
    });
  }

  void pausePublishedMusic() {
    if (_cloud == null || !_publishedMusicPlaying) return;
    _cloud!.getAudioEffectManager().pausePlayMusic(voiceRoomMusicId);
    _publishedMusicPlaying = false;
    VoiceRoomDebugLog.log('trtc.music.publish.pause', {});
  }

  void resumePublishedMusic() {
    if (_cloud == null) return;
    _cloud!.getAudioEffectManager().resumePlayMusic(voiceRoomMusicId);
    _publishedMusicPlaying = true;
    VoiceRoomDebugLog.log('trtc.music.publish.resume', {});
  }

  void stopPublishedMusic() {
    if (_cloud == null) return;
    try {
      _cloud!.getAudioEffectManager().stopPlayMusic(voiceRoomMusicId);
    } catch (_) {}
    _publishedMusicPlaying = false;
  }

  Future<void> disposeAsync() async {
    _trtcLog('dispose');
    stopPublishedMusic();
    await leave();
    _cloud = null;
    _device = null;
    if (!_notifiersDisposed) {
      _notifiersDisposed = true;
      remoteAnchorUserIdNotifier.dispose();
      remoteVideoAvailable.dispose();
      remoteVideoByUser.dispose();
      remoteAudioByUser.dispose();
      networkQuality.dispose();
      remoteUserIdsNotifier.dispose();
      speakingUsersNotifier.dispose();
    }
  }

  void dispose() {
    unawaited(disposeAsync());
  }

  static void destroyEngine() {
    try {
      TRTCCloud.destroySharedInstance();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TRTC destroy: $e');
      }
    }
  }
}

/// Yerel kamera önizlemesi.
class TrtcLocalVideoView extends StatelessWidget {
  const TrtcLocalVideoView({super.key, required this.manager});

  final TrtcRoomManager manager;

  @override
  Widget build(BuildContext context) {
    return TRTCCloudVideoView(
      onViewCreated: (viewId) => manager.startLocalPreview(viewId),
    );
  }
}

/// Uzak yayıncı videosu — view dispose'da binding temizlenir.
class TrtcRemoteVideoView extends StatefulWidget {
  const TrtcRemoteVideoView({
    super.key,
    required this.manager,
    required this.userId,
  });

  final TrtcRoomManager manager;
  final String userId;

  @override
  State<TrtcRemoteVideoView> createState() => _TrtcRemoteVideoViewState();
}

class _TrtcRemoteVideoViewState extends State<TrtcRemoteVideoView> {
  @override
  void dispose() {
    widget.manager.stopRemoteView(widget.userId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TRTCCloudVideoView(
      key: ValueKey('remote-${widget.userId}'),
      onViewCreated: (viewId) {
        widget.manager.startRemoteView(widget.userId, viewId);
        // Video zaten available ise (timer başlamadan geldiyse), resubscribe et.
        // Bu race condition'da: onUserVideoAvailable → view henüz yok;
        // sonra timer start → view oluşturuluyor → subscribe olmalı.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.manager.remoteVideoByUser.value[widget.userId] == true) {
            widget.manager.resubscribeRemoteView(widget.userId);
          }
        });
      },
    );
  }
}
