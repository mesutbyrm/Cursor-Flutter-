#include "include/tencent_rtc_sdk/trtc_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "trtc_plugin.h"

void TrtcPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  trtc::TrtcPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
