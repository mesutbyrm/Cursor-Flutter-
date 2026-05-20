#include "texture_view_factory.h"
#include <functional>
#include <iostream>
#include <vector>

using namespace flutter;
using std::string;

std::map<int64_t, SP<TextureRenderer>> texture_map_ = std::map<int64_t, SP<TextureRenderer>>();
std::map<std::string, int64_t> user_view_map_ = std::map<std::string, int64_t>();

TextureRenderer::TextureRenderer(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar) {
  texture_ =
      std::make_unique<flutter::TextureVariant>(flutter::PixelBufferTexture(
          [=](size_t width, size_t height) -> const FlutterDesktopPixelBuffer* {
            const std::lock_guard<std::mutex> lock(mutex_);
            return &flutter_pixel_buffer_;
          }));
  texture_registrar_ = registrar_->texture_registrar();
  texture_id_ = texture_registrar_->RegisterTexture(texture_.get());
  method_channel_ = MK_SP<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "tencent_rtc_texture_" + std::to_string(texture_id_),
          &flutter::StandardMethodCodec::GetInstance());
}

TextureRenderer::~TextureRenderer() {
  texture_registrar_->UnregisterTexture(texture_id_);
  texture_registrar_ = nullptr;
}

// TRTCVideoRenderCallback
void TextureRenderer::onRenderVideoFrame(const char* user_id, TRTCVideoStreamType stream_type, TRTCVideoFrame* video_frame) {
  // std::cout << "Value of user_id1 is : " << user_id << std::endl;
  std::lock_guard<std::mutex> lock_guard(mutex_);
  if (texture_width_ != video_frame->width || texture_height_ != video_frame->height) {
      texture_width_ = video_frame->width;
      texture_height_ = video_frame->height;
      EncodableMap params;
      params[string("width")] = (int)texture_width_;
      params[string("height")] = (int)texture_height_;
      method_channel_->InvokeMethod("updateVideoAspectRatio", std::make_unique<EncodableValue>(params));
  }
  // BGRA TO RGBA
  uint32_t * rbga = (uint32_t *)video_frame->data;
  for (int i = 0; i < (int)video_frame->width * (int)video_frame->height; i++) {
    rbga[i] = ((rbga[i] & 0xFF000000)) |        // ______AA
            ((rbga[i] & 0x00FF0000) >> 16) | // RR______
            ((rbga[i] & 0x0000FF00)) |         // __GG____
            ((rbga[i] & 0x000000FF) << 16);  // ____BB__
  }
  // flutter_pixel_buffer_.buffer = (const uint8_t *)video_frame->data;
  flutter_pixel_buffer_.buffer = (uint8_t*)rbga;
  flutter_pixel_buffer_.width = video_frame->width;
  flutter_pixel_buffer_.height = video_frame->height;
  if (texture_registrar_) {
    texture_registrar_->MarkTextureFrameAvailable(texture_id_);
  }
}

// V2TXLivePlayerObserver
void TextureRenderer::onRenderVideoFrame(liteav::V2TXLivePlayer* player, const liteav::V2TXLiveVideoFrame* videoFrame) {
  std::lock_guard<std::mutex> lock_guard(mutex_);
  
  if (!videoFrame || !videoFrame->data || videoFrame->width <= 0 || videoFrame->height <= 0) {
    return;
  }
  
  size_t buffer_size = videoFrame->width * videoFrame->height * 4;
  
  static thread_local std::vector<uint8_t> conversion_buffer;
  if (conversion_buffer.size() < buffer_size) {
    conversion_buffer.resize(buffer_size);
  }
  
  // BGRA TO RGBA
  uint32_t *src = (uint32_t *)videoFrame->data;
  uint32_t *dst = (uint32_t *)conversion_buffer.data();
  
  for (int i = 0; i < (int)videoFrame->width * (int)videoFrame->height; i++) {
    uint32_t pixel = src[i];
    dst[i] = ((pixel & 0xFF000000)) |        // ______AA (Alpha)
             ((pixel & 0x00FF0000) >> 16) |  // RR______ (Red)
             ((pixel & 0x0000FF00)) |        // __GG____ (Green)
             ((pixel & 0x000000FF) << 16);   // ____BB__ (Blue)
  }

  flutter_pixel_buffer_.buffer = conversion_buffer.data();
  flutter_pixel_buffer_.width = videoFrame->width;
  flutter_pixel_buffer_.height = videoFrame->height;
  
  if (texture_registrar_) {
    texture_registrar_->MarkTextureFrameAvailable(texture_id_);
  }
}