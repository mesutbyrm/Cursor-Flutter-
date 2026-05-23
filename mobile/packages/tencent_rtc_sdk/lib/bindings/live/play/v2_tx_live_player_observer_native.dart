import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:tencent_rtc_sdk/bindings/live/live_load_dynamic_lib.dart';
import 'package:tencent_rtc_sdk/bindings/live/live_log.dart';
import 'package:tencent_rtc_sdk/v2_tx_live_def.dart';
import 'package:tencent_rtc_sdk/v2_tx_live_player_observer.dart';

import 'v2_tx_live_player_ffi_bindings.dart' as native;

class V2TXLivePlayerObserverNative {
  final Set<V2TXLivePlayerObserver> _observers = {};

  late native.V2TXLivePlayerFFIBindings _observerFFIBindings;
  late Pointer<native.V2TXLivePlayerNativePointer> _playerNativePointer;

  late ReceivePort _receivePort;
  int _textureId = -1;
  int _renderWidth = -1;
  int _renderHeight = -1;
  int _videoWidth = -1;
  int _videoHeight = -1;

  V2TXLivePlayerObserverNative(Pointer<native.V2TXLivePlayerNativePointer> playerNativePointer) {
    _playerNativePointer = playerNativePointer;

    _receivePort = ReceivePort();
    _receivePort.listen(_receiveNativePortData);

    _observerFFIBindings = native.V2TXLivePlayerFFIBindings(LiveLoadDynamicLib.getLiteavSDK());
    _observerFFIBindings.InitDartApiDL(NativeApi.initializeApiDLData);
    _observerFFIBindings.registerPlayerListener(_receivePort.sendPort.nativePort, _playerNativePointer);
  }

  void addListener(V2TXLivePlayerObserver observer) {
    _observers.add(observer);
  }

  void removeListener(V2TXLivePlayerObserver observer) {
    _observers.remove(observer);
  }

  void unRegisterNativeListener() {
    _observers.clear();
    _receivePort.close();
    _observerFFIBindings.unRegisterPlayerListener(_playerNativePointer);
  }

  void setTextureId(int textureId) {
    LiveLog.playerPrint(
      _playerNativePointer,
      V2TXLiveLogLevel.v2TXLiveLogLevelInfo,
      "V2TXLivePlayerObserverNative.setTextureId: textureId: $textureId",
    );
    if (textureId < 0) {
      return;
    }
    if (textureId == _textureId) {
      return;
    }
    _textureId = textureId;
    _updateTextureBufferSize();
  }

  void setTextureBufferSize(int width, int height) {
    LiveLog.playerPrint(
      _playerNativePointer,
      V2TXLiveLogLevel.v2TXLiveLogLevelInfo,
      "V2TXLivePlayerObserverNative.setTextureBufferSize: width: $width, height: $height",
    );
    if (width <= 0 || height <= 0) {
      return;
    }
    if (_renderWidth == width && _renderHeight == height) {
      return;
    }
    _renderWidth = width;
    _renderHeight = height;
    _updateTextureBufferSize();
  }

  void _updateTextureBufferSize() {
    LiveLog.playerPrint(
      _playerNativePointer,
      V2TXLiveLogLevel.v2TXLiveLogLevelInfo,
      "V2TXLivePlayerObserverNative._updateTextureBufferSize: _textureId: $_textureId, _renderWidth: $_renderWidth, _renderHeight: $_renderHeight, _videoWidth: $_videoWidth, _videoHeight: $_videoHeight",
    );
    if (_textureId == -1) {
      return;
    }

    if (_renderHeight <= 0 || _renderWidth <= 0) {
      return;
    }

    var scale = 1.0;

    if (_renderWidth > 0 && _renderHeight > 0 && _videoWidth > 0 && _videoHeight > 0) {
      var heightScale = _videoHeight / _renderHeight;
      var widthScale = _videoWidth / _renderWidth;

      scale = max(max(heightScale, widthScale), 1);
    }

    LiveLoadDynamicLib.getPluginChannel().invokeMethod('setTextureBufferSize', {
      "textureId": _textureId,
      "width": _renderWidth * scale,
      "height": _renderHeight * scale,
    });
  }

  _receiveNativePortData(var message) {
    var arguments = jsonDecode(message);
    String typeStr = arguments['type'];
    var params = arguments['params'];

    V2TXLivePlayerListenerType? type;

    for (var item in V2TXLivePlayerListenerType.values) {
      if (item.toString().replaceFirst("V2TXLivePlayerListenerType.", "") == typeStr) {
        type = item;

        if (type == V2TXLivePlayerListenerType.onReceiveSeiMessage) {
          Uint8List decodedBytes = base64Decode(params['data']);
          params['data'] = decodedBytes;
        }

        if (type == V2TXLivePlayerListenerType.onSnapshotComplete) {
          final imageData = params.remove('image');
          if (imageData is String && imageData.isNotEmpty) {
            params['image'] = base64Decode(imageData);
          }
        }

        if (type == V2TXLivePlayerListenerType.onVideoResolutionChanged) {
          int width = params['width'].toInt();
          int height = params['height'].toInt();
          LiveLog.playerPrint(
            _playerNativePointer,
            V2TXLiveLogLevel.v2TXLiveLogLevelInfo,
            "V2TXLivePlayerObserverNative.onVideoResolutionChanged: width: $width, height: $height",
          );
          if (width != _videoWidth || height != _videoHeight) {
            _videoWidth = width;
            _videoHeight = height;
            _updateTextureBufferSize();
          }
        }
        break;
      }
    }
    if (type == null) {
      throw MissingPluginException();
    }
    for (var item in _observers) {
      item(type, params);
    }
  }
}
