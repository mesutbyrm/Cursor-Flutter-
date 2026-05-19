#ifndef FLUTTER_PLUGIN_TRTC_PLUGIN_H_
#define FLUTTER_PLUGIN_TRTC_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include "include/macros.h"
#include "include/TRTC/ITRTCCloud.h"

namespace trtc {

class TrtcPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  TrtcPlugin(flutter::PluginRegistrarWindows *registrar, SP<flutter::MethodChannel<>> channel);

  virtual ~TrtcPlugin();

  // Disallow copy and assign.
  TrtcPlugin(const TrtcPlugin&) = delete;
  TrtcPlugin& operator=(const TrtcPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  int64_t createTextureView();
  void disposeTextureView(int64_t texture_id);

  void startLocalPreview(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void startRemoteView(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void stopLocalPreview(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void stopRemoteView(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void updateLocalView(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void updateRemoteView(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void getCustomVideoFrameListener(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void getTextureId(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void unregisterTexture(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  SP<flutter::MethodChannel<flutter::EncodableValue>> method_channel_;
  flutter::PluginRegistrarWindows *registrar_;
};

}  // namespace trtc

#endif  // FLUTTER_PLUGIN_TRTC_PLUGIN_H_
