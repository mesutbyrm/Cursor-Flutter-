import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:tencent_rtc_sdk/v2_tx_live_def.dart';

class LiveLoadDynamicLib {
  static DynamicLibrary dynamicLibraryLiteavSDK = _loadLiteavSDK();
  static MethodChannel pluginChannel = _getPluginChannel();

  static DynamicLibrary getLiteavSDK() {
    return dynamicLibraryLiteavSDK;
  }

  static MethodChannel getPluginChannel() {
    return pluginChannel;
  }

  static DynamicLibrary _loadLiteavSDK() {
    if (Platform.isIOS || Platform.isMacOS) {
      return DynamicLibrary.process();
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('liteav.dll');
    } else {
      return DynamicLibrary.open("libliteavsdk.so");
    }
  }

  static MethodChannel _getPluginChannel() {
    return const MethodChannel('TencentRTCffi');
  }
}
