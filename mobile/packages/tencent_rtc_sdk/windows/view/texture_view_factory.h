#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>
#include <flutter/plugin_registrar_windows.h>
#include <map>
#include <mutex>
#include "../include/TRTC/TRTCCloudCallback.h"
#include "../include/macros.h"
#include "../include/Live2/V2TXLivePlayerObserver.hpp"
#include "../include/Live2/V2TXLivePlayer.hpp"
#include "../include/Live2/V2TXLiveDef.hpp"

class TextureRenderer : public ITRTCVideoRenderCallback, public liteav::V2TXLivePlayerObserver {
public:
  TextureRenderer(flutter::PluginRegistrarWindows *registrar);
  ~TextureRenderer();

  int64_t texture_id() const { return texture_id_; }

  void onRenderVideoFrame(const char* user_id, TRTCVideoStreamType stream_type, TRTCVideoFrame* frame);
  void onRenderVideoFrame(liteav::V2TXLivePlayer *player, const liteav::V2TXLiveVideoFrame *videoFrame);

private:
  const FlutterDesktopPixelBuffer *CopyPixelBuffer(size_t width, size_t height);

public:
 SP<flutter::MethodChannel<>> method_channel_;
  flutter::PluginRegistrarWindows *registrar_;
  std::unique_ptr<flutter::TextureVariant> texture_;
  int64_t texture_id_;
  uint32_t texture_width_;
  uint32_t texture_height_;
  std::unique_ptr<flutter::MethodCall<flutter::EncodableValue>> channel_;
  std::string user_id_;
  std::string channel_id_;
  mutable std::mutex mutex_;
  FlutterDesktopPixelBuffer *pixel_buffer_;

  FlutterDesktopPixelBuffer flutter_pixel_buffer_{};
  flutter::TextureRegistrar* texture_registrar_ = nullptr;
};

extern std::map<int64_t, SP<TextureRenderer>> texture_map_;
extern std::map<std::string, int64_t> user_view_map_;
