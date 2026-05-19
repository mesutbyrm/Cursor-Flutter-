package com.tencent.trtcplugin;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.Handler;
import android.os.Looper;
import android.view.Surface;

import androidx.annotation.NonNull;

import com.tencent.liteav.live.V2TXLivePremierJni;
import com.tencent.live.beauty.custom.ITXCustomBeautyProcesser;
import com.tencent.live.beauty.custom.ITXCustomBeautyProcesserFactory;
import com.tencent.live.beauty.custom.TXCustomBeautyDef;
import com.tencent.trtc.TRTCCloud;
import com.tencent.trtc.TRTCCloudDef;
import com.tencent.trtc.TRTCCloudListener;
import com.tencent.trtcplugin.utils.CommonUtil;
import com.tencent.trtcplugin.utils.ImageIO;
import com.tencent.trtcplugin.utils.ObjectUtils;
import com.tencent.trtcplugin.utils.ProcessVideoFrame;
import com.tencent.trtcplugin.utils.TRTCLogger;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;
import io.flutter.view.TextureRegistry.SurfaceTextureEntry;

public class TRTCCloudManager {
    private Context mContext;
    private MethodChannel mChannel;

    private ITXCustomBeautyProcesser mCustomBeautyProcesser;
    private ExecutorService mExecutor = Executors.newSingleThreadExecutor();
    private Handler mMainHandler = new Handler(Looper.getMainLooper());

    private Bitmap mMuteImage;

    private TextureRegistry mTextureRegister;
    private final HashMap<Long, SurfaceTextureEntry> mEntryHashMap = new HashMap<>();
    private final HashMap<Long, Surface> mSurfaceHashMap = new HashMap<>();
    private final HashMap<Long, Long> mSurfaceAddressHashMap = new HashMap<>();

    private AITranscriberManagerHandler mTranscriberHandler;

    TRTCCloudManager(Context context, MethodChannel channel, TextureRegistry register) {
        mContext = context;
        mChannel = channel;
        mTextureRegister = register;
        mTranscriberHandler = new AITranscriberManagerHandler(context, channel);
        channel.setMethodCallHandler(this::onMethodCall);
    }

    public void release() {
        mChannel.setMethodCallHandler(null);
        mMainHandler.removeCallbacksAndMessages(null);
        mExecutor.shutdown();
        if (mMuteImage != null) {
            mMuteImage.recycle();
        }
        if (mTranscriberHandler != null) {
            mTranscriberHandler.release();
        }
    }

    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (!TRTCPlugin.ensureNativeLibrary()) {
            result.error(
                    "NATIVE_LOAD_FAILED",
                    "Tencent RTC native library could not be loaded",
                    null);
            return;
        }
        // 首先尝试让 AITranscriberManagerHandler 处理
        if (mTranscriberHandler != null && mTranscriberHandler.handleMethodCall(call, result)) {
            return;
        }

        try {
            Method method = TRTCCloudManager.class.getDeclaredMethod(call.method, MethodCall.class, MethodChannel.Result.class);
            method.invoke(this, call, result);
        } catch (NoSuchMethodException e) {
            TRTCLogger.e("method=" + call.method + " | arguments=" + call.arguments + " | error=" + e);
        } catch (IllegalAccessException e) {
            TRTCLogger.e("method=" + call.method + " | arguments=" + call.arguments + " | error=" + e);
        } catch (Exception e) {
            TRTCLogger.e("method=" + call.method + " | arguments=" + call.arguments + " | error=" + e);
        }
    }

    private void initialize(MethodCall call, MethodChannel.Result result) {
        result.success(null);
    }

    private void snapshotVideo(MethodCall call, MethodChannel.Result result) {
        String userId = CommonUtil.getParam(call, result, "userId");
        int streamType = CommonUtil.getParam(call, result, "streamType");
        int sourceType = CommonUtil.getParam(call, result, "sourceType");
        String path = CommonUtil.getParam(call, result, "path");
        TRTCCloud.sharedInstance(mContext).snapshotVideo(userId, streamType, sourceType, new TRTCCloudListener.TRTCSnapshotListener() {
            @Override
            public void onSnapshotComplete(Bitmap bitmap) {
                submitExecute(() -> {
                    ImageIO.SaveResult saveResult = ImageIO.save(mContext, bitmap, path);
                    mMainHandler.post(() -> notifySnapshotComplete(userId, saveResult));
                }, "snapshot save");
            }
        });
        result.success(null);
    }

    private void setVideoMuteImage(MethodCall call, MethodChannel.Result result) {
        String filePath = CommonUtil.getParam(call, result, "imagePath");
        int fps = CommonUtil.getParam(call, result, "fps");

        submitExecute(() -> {
            if (mMuteImage != null) {
                mMuteImage.recycle();
            }
            mMuteImage = ImageIO.loadBitmapFromFile(mContext, filePath);
            mMainHandler.post(() -> {
                if (mMuteImage == null) {
                    TRTCLogger.e(" setVideoMuteImage | failed to load bitmap");
                } else {
                    TRTCCloud.sharedInstance(mContext).setVideoMuteImage(mMuteImage, fps);
                }
            });
        }, "setVideoMuteImage");

        result.success(null);
    }

    private void setWatermark(MethodCall call, MethodChannel.Result result) {
        String filePath = CommonUtil.getParam(call, result, "imagePath");
        int streamType = CommonUtil.getParam(call, result, "streamType");
        double x = CommonUtil.getParam(call, result, "x");
        double y = CommonUtil.getParam(call, result, "y");
        double width = CommonUtil.getParam(call, result, "width");

        submitExecute(() -> {
            Bitmap watermark = ImageIO.loadBitmapFromFile(mContext, filePath);
            mMainHandler.post(() -> {
                if (watermark == null) {
                    TRTCLogger.e(" setWatermark | failed to load bitmap");
                } else {
                    TRTCCloud.sharedInstance(mContext).setWatermark(watermark, streamType, (float) x, (float) y, (float) width);
                }
            });
        }, "setWatermark");

        result.success(null);
    }

    private void enableVideoProcessByNative(MethodCall call, MethodChannel.Result result) {
        boolean enable = CommonUtil.getParam(call, result, "enable");
        ITXCustomBeautyProcesserFactory processFactory = TRTCPlugin.getBeautyProcesserFactory();
        if (enable) {
            if (mCustomBeautyProcesser == null) {
                mCustomBeautyProcesser = processFactory.createCustomBeautyProcesser();
            }
            TXCustomBeautyDef.TXCustomBeautyBufferType bufferType = mCustomBeautyProcesser.getSupportedBufferType();
            TXCustomBeautyDef.TXCustomBeautyPixelFormat pixelFormat = mCustomBeautyProcesser.getSupportedPixelFormat();
            ProcessVideoFrame processVideo = new ProcessVideoFrame(mCustomBeautyProcesser);
            int ret = TRTCCloud.sharedInstance(mContext).setLocalVideoProcessListener(ObjectUtils.convertTRTCPixelFormat(pixelFormat),
                    ObjectUtils.convertTRTCBufferType(bufferType), processVideo);
            result.success(ret);
        } else {
            if (mCustomBeautyProcesser != null) {
                processFactory.destroyCustomBeautyProcesser();
                mCustomBeautyProcesser = null;
            }
            int ret = TRTCCloud.sharedInstance(mContext).setLocalVideoProcessListener(TRTCCloudDef.TRTC_VIDEO_PIXEL_FORMAT_UNKNOWN,
                    TRTCCloudDef.TRTC_VIDEO_BUFFER_TYPE_UNKNOWN, null);
            result.success(ret);
        }
    }

    private void getTextureId(MethodCall call, MethodChannel.Result result) {
        SurfaceTextureEntry surfaceTexture = mTextureRegister.createSurfaceTexture();
        long textureId = surfaceTexture.id();
        mEntryHashMap.put(textureId, surfaceTexture);
        result.success(textureId);
    }

    private void getSurfaceId(MethodCall call, MethodChannel.Result result) {
        Integer textureId = CommonUtil.getParam(call, result, "textureId");
        if (textureId == null) {
            result.success(0);
            return;
        }
        Long surfaceAddress = mSurfaceAddressHashMap.get(textureId.longValue());
        if (surfaceAddress != null) {
            result.success(surfaceAddress);
            return;
        }
        SurfaceTextureEntry surfaceTextureEntry = mEntryHashMap.get(textureId.longValue());
        if (surfaceTextureEntry == null) {
            result.success(0);
            return;
        }
        Surface surface = new Surface(surfaceTextureEntry.surfaceTexture());
        surfaceAddress = V2TXLivePremierJni.getObjectAddress(surface);
        mSurfaceHashMap.put(textureId.longValue(), surface);
        mSurfaceAddressHashMap.put(textureId.longValue(), surfaceAddress);
        result.success(surfaceAddress);
    }

    private void setTextureBufferSize(MethodCall call, MethodChannel.Result result) {
        Integer textureId = CommonUtil.getParam(call, result, "textureId");
        if (textureId == null) {
            result.success(null);
            return;
        }
        SurfaceTextureEntry surfaceTextureEntry = mEntryHashMap.get(textureId.longValue());
        if (surfaceTextureEntry == null) {
            result.success(null);
            return;
        }
        Double width = CommonUtil.getParam(call, result, "width");
        Double height = CommonUtil.getParam(call, result, "height");
        if (width == null || height == null || width <= 0 || height <= 0) {
            result.success(null);
            return;
        }
        surfaceTextureEntry.surfaceTexture().setDefaultBufferSize(width.intValue(), height.intValue());
        result.success(null);
    }

    private void unregisterTexture(MethodCall call, MethodChannel.Result result) {
        Integer textureId = CommonUtil.getParam(call, result, "textureId");
        if (textureId == null) {
            result.success(null);
            return;
        }
        SurfaceTextureEntry surfaceTextureEntry = mEntryHashMap.get(textureId.longValue());
        if (surfaceTextureEntry != null) {
            surfaceTextureEntry.release();
        }
        Long surfaceAddress = mSurfaceAddressHashMap.get(textureId.longValue());
        if (surfaceAddress != null) {
            V2TXLivePremierJni.releaseObjectAddress(surfaceAddress);
        }
        mEntryHashMap.remove(textureId.longValue());
        mSurfaceHashMap.remove(textureId.longValue());
        mSurfaceAddressHashMap.remove(textureId.longValue());
        result.success(null);
    }

    private void getCustomVideoProcessListener(MethodCall call, MethodChannel.Result result) {
        result.success(V2TXLivePremierJni.getObjectAddress(TRTCPlugin.getCustomVideoProcessObserver()));
    }

    private void notifySnapshotComplete(String userId, ImageIO.SaveResult result) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", userId);
        params.put("path", result.path);
        params.put("errCode", result.code);
        params.put("errMsg", result.message);

        mChannel.invokeMethod("onSnapshotComplete", params);
    }

    private void destroySharedInstance(MethodCall call, MethodChannel.Result result) {
        TRTCCloud.destroySharedInstance();
        result.success(null);
    }

    private void submitExecute(Runnable task, String operationName) {
        if (mExecutor.isShutdown() || mExecutor.isTerminated()) {
            TRTCLogger.w("Thread pool is shutdown, skip " + operationName + " operation");
            return;
        }

        try {
            mExecutor.execute(task);
            return;
        } catch (Exception e) {
            TRTCLogger.e("Failed to submit " + operationName + " task to executor: " + e.getMessage());
            return;
        }
    }
}
