#include "trtc_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>

#include "view/texture_view_factory.h"

namespace trtc {

// static std::map<int64_t, TextureRenderer*> texture_map_ = std::map<int64_t, TextureRenderer*>();

// static
void TrtcPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      MK_SP<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "TencentRTCffi",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<TrtcPlugin>(registrar, channel);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

TrtcPlugin::TrtcPlugin(flutter::PluginRegistrarWindows *registrar, SP<flutter::MethodChannel<>> channel) {
  registrar_ = registrar;
  method_channel_ = channel;
}

TrtcPlugin::~TrtcPlugin() {}

void TrtcPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::string method_name = method_call.method_name();
  if (method_name.compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else if (method_name.compare("initialize") == 0) {
    result->Success(nullptr);
  } else if (method_name.compare("trtcLog") == 0) {
    result->Success(nullptr);
  } else if (method_name.compare("createTextureView") == 0) {
    int64_t texture_id = createTextureView();
    result->Success(flutter::EncodableValue(texture_id));
  } else if (method_name.compare("disposeTextureView") == 0) {
    auto method_params = std::get<flutter::EncodableMap>(*method_call.arguments());
    auto texture_id = std::get<int64_t>(method_params[flutter::EncodableValue("textureId")]);
    disposeTextureView(texture_id);
    result->Success(nullptr);
  } else if (method_name.compare("startLocalPreview") == 0) {
    startLocalPreview(method_call, std::move(result));
  } else if (method_name.compare("startRemoteView") == 0) {
    startRemoteView(method_call, std::move(result));
  } else if (method_name.compare("stopLocalPreview") == 0) {
    stopLocalPreview(method_call, std::move(result));
  } else if (method_name.compare("stopRemoteView") == 0) {
    stopRemoteView(method_call, std::move(result));
  } else if (method_name.compare("updateLocalView") == 0) {
    updateLocalView(method_call, std::move(result));
  } else if (method_name.compare("updateRemoteView") == 0) {
    updateRemoteView(method_call, std::move(result));
  } else if (method_name.compare("getCustomVideoFrameListener") == 0) {
    getCustomVideoFrameListener(method_call, std::move(result));
  } else if (method_name.compare("getTextureId") == 0) {
    getTextureId(method_call, std::move(result));
  } else if (method_name.compare("getSurfaceId") == 0) {
    result->Success(nullptr);
  } else if (method_name.compare("unregisterTexture") == 0) {
    unregisterTexture(method_call, std::move(result));
  } else if (method_name.compare("setTextureBufferSize") == 0) {
    result->Success(nullptr);
  } else {
    result->NotImplemented();
  }
}

int64_t TrtcPlugin::createTextureView() {
  SP<TextureRenderer> texture_renderer = MK_SP<TextureRenderer>(registrar_);
  int64_t texture_id = texture_renderer->texture_id();
  texture_map_[texture_id] = texture_renderer;
  return texture_id;
}

void TrtcPlugin::disposeTextureView(int64_t texture_id) {
  SP<TextureRenderer> texture_renderer = texture_map_[texture_id];
  texture_map_.erase(texture_id);

  std::string user_id = texture_renderer->user_id_;
  if (user_view_map_[user_id] == texture_id) {
    if (user_id == "") {
      getTRTCShareInstance()->stopLocalPreview();
      getTRTCShareInstance()->setLocalVideoRenderCallback(TRTCVideoPixelFormat_Unknown, TRTCVideoBufferType_Unknown, nullptr);
    } else {
      getTRTCShareInstance()->stopRemoteView(user_id.c_str(), TRTCVideoStreamTypeBig);
      getTRTCShareInstance()->setRemoteVideoRenderCallback(user_id.c_str(), TRTCVideoPixelFormat_Unknown, TRTCVideoBufferType_Unknown, nullptr);
    }
    user_view_map_.erase(user_id);
  }
}

void TrtcPlugin::startLocalPreview(
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto methodParams = std::get<flutter::EncodableMap>(*method_call.arguments());
  auto viewId = std::get<int64_t>(methodParams[flutter::EncodableValue("viewId")]);

  if (!texture_map_[viewId]) {
    result->Success(nullptr);
    return;
  }
  user_view_map_[""] = viewId;
  texture_map_[viewId]->user_id_ = "";

  getTRTCShareInstance()->startLocalPreview(nullptr);
  getTRTCShareInstance()->setLocalVideoRenderCallback(TRTCVideoPixelFormat_BGRA32, TRTCVideoBufferType_Buffer, texture_map_[viewId].get());
  result->Success(nullptr);
}

void TrtcPlugin::startRemoteView(
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto methodParams = std::get<flutter::EncodableMap>(*method_call.arguments());
  auto viewId = std::get<int64_t>(methodParams[flutter::EncodableValue("viewId")]);
  auto streamType = std::get<int>(methodParams[flutter::EncodableValue("streamType")]);
  auto user_id = std::get<std::string>(methodParams[flutter::EncodableValue("userId")]);
  TRTCVideoStreamType stype = static_cast<TRTCVideoStreamType>(streamType);

  if (!texture_map_[viewId]) {
    result->Success(nullptr);
    return;
  }
  user_view_map_[user_id] = viewId;
  texture_map_[viewId]->user_id_ = user_id;

  getTRTCShareInstance()->startRemoteView(user_id.c_str(), stype, nullptr);
  getTRTCShareInstance()->setRemoteVideoRenderCallback(user_id.c_str(), TRTCVideoPixelFormat_BGRA32, TRTCVideoBufferType_Buffer, texture_map_[viewId].get());
  result->Success(nullptr);
}

void TrtcPlugin::stopLocalPreview(
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  user_view_map_.erase("");

  getTRTCShareInstance()->stopLocalPreview();
  getTRTCShareInstance()->setLocalVideoRenderCallback(TRTCVideoPixelFormat_Unknown, TRTCVideoBufferType_Unknown, nullptr);
  result->Success(nullptr);
}

void TrtcPlugin::stopRemoteView(
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto methodParams = std::get<flutter::EncodableMap>(*method_call.arguments());
  auto streamType = std::get<int>(methodParams[flutter::EncodableValue("streamType")]);
  auto user_id = std::get<std::string>(methodParams[flutter::EncodableValue("userId")]);
  TRTCVideoStreamType stype = static_cast<TRTCVideoStreamType>(streamType);

  user_view_map_.erase(user_id);

  getTRTCShareInstance()->stopRemoteView(user_id.c_str(), stype);
  getTRTCShareInstance()->setRemoteVideoRenderCallback(user_id.c_str(), TRTCVideoPixelFormat_Unknown, TRTCVideoBufferType_Unknown, nullptr);
  result->Success(nullptr);
}
void TrtcPlugin::updateLocalView(
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto methodParams = std::get<flutter::EncodableMap>(*method_call.arguments());
  auto viewId = std::get<int64_t>(methodParams[flutter::EncodableValue("viewId")]);

  if (!texture_map_[viewId]) {
    result->Success(nullptr);
    return;
  }
  user_view_map_[""] = viewId;
  texture_map_[viewId]->user_id_ = "";

  getTRTCShareInstance()->startLocalPreview(nullptr);
  getTRTCShareInstance()->setLocalVideoRenderCallback(TRTCVideoPixelFormat_BGRA32, TRTCVideoBufferType_Buffer, texture_map_[viewId].get());
  result->Success(nullptr);
}
void TrtcPlugin::updateRemoteView(
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto methodParams = std::get<flutter::EncodableMap>(*method_call.arguments());
  auto viewId = std::get<int64_t>(methodParams[flutter::EncodableValue("viewId")]);
  auto user_id = std::get<std::string>(methodParams[flutter::EncodableValue("userId")]);

  if (!texture_map_[viewId]) {
    result->Success(nullptr);
    return;
  }
  user_view_map_[user_id] = viewId;
  texture_map_[viewId]->user_id_ = user_id;

  getTRTCShareInstance()->setRemoteVideoRenderCallback(user_id.c_str(), TRTCVideoPixelFormat_BGRA32, TRTCVideoBufferType_Buffer, texture_map_[viewId].get());
  result->Success(nullptr);
}

void TrtcPlugin::getCustomVideoFrameListener(
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
  auto texture_id = std::get<int64_t>(arguments[flutter::EncodableValue("textureId")]);

  if (texture_map_.find(texture_id) == texture_map_.end()) {
    result->Error("INVALID_ARGUMENT", "No observer found for textureId");
    return;
  }

  auto texture_renderer = texture_map_[texture_id].get();
  liteav::V2TXLivePlayerObserver* observer = static_cast<liteav::V2TXLivePlayerObserver*>(texture_renderer);
  
  intptr_t ptr_value = reinterpret_cast<intptr_t>(observer);
  result->Success(flutter::EncodableValue(ptr_value));
}

void TrtcPlugin::getTextureId(
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (!texture_map_.empty()) {
    auto existing_texture_id = texture_map_.begin()->first;
    result->Success(flutter::EncodableValue(existing_texture_id));
    return;
  }

  auto texture_id = createTextureView();
  result->Success(flutter::EncodableValue(texture_id));
}

void TrtcPlugin::unregisterTexture(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    auto texture_id = std::get<int64_t>(arguments[flutter::EncodableValue("textureId")]);
    
    if (texture_map_.find(texture_id) == texture_map_.end()) {
      result->Error("INVALID_ARGUMENT", "Texture not found");
      return;
    }
    
    texture_map_.erase(texture_id);
    registrar_->texture_registrar()->UnregisterTexture(texture_id);

    result->Success(nullptr);
}

}  // namespace trtc
