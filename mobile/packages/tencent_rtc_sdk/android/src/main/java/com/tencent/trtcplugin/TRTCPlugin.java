package com.tencent.trtcplugin;

import android.content.Context;
import androidx.annotation.NonNull;

import com.tencent.live.beauty.custom.ITXCustomBeautyProcesserFactory;
import com.tencent.trtcplugin.utils.TRTCLogger;
import com.tencent.trtcplugin.view.TRTCPlatformViewFactory;
import com.tencent.live2.V2TXLivePusherObserver;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformViewRegistry;

public class TRTCPlugin implements FlutterPlugin {
    public static final String TAG = "trtc-flutter";

    private static volatile boolean sNativeLoaded = false;
    private static volatile boolean sNativeLoadFailed = false;

    /**
     * Native lib yüklemesini uygulama açılışından erteleyerek başlangıç çökmesini önler.
     * İlk TRTC çağrısında yüklenir; hata olursa false döner.
     */
    public static synchronized boolean ensureNativeLibrary() {
        if (sNativeLoaded) {
            return true;
        }
        if (sNativeLoadFailed) {
            return false;
        }
        try {
            System.loadLibrary("liteavsdk");
            sNativeLoaded = true;
            return true;
        } catch (Throwable t) {
            sNativeLoadFailed = true;
            TRTCLogger.e("loadLibrary liteavsdk failed: " + t.getMessage());
            return false;
        }
    }
    
    private static ITXCustomBeautyProcesserFactory sProcessFactory;
    
    private static V2TXLivePusherObserver sObserver;

    public static ITXCustomBeautyProcesserFactory getBeautyProcesserFactory() {
        return sProcessFactory;
    }
    
    public static void setBeautyProcesserFactory(ITXCustomBeautyProcesserFactory factory) {
        sProcessFactory = factory;
    }

    public static void registerObserver(V2TXLivePusherObserver observer) {
        sObserver = observer;
    }

    public static V2TXLivePusherObserver getCustomVideoProcessObserver() {
        return sObserver;
    }

    private TRTCCloudManager mCloudManager;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        Context context = flutterPluginBinding.getApplicationContext();
        MethodChannel methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "TencentRTCffi");
        mCloudManager = new TRTCCloudManager(context, methodChannel, flutterPluginBinding.getTextureRegistry());

        PlatformViewRegistry registry = flutterPluginBinding.getPlatformViewRegistry();
        registry.registerViewFactory("TRTCPlatformView", new TRTCPlatformViewFactory(flutterPluginBinding.getBinaryMessenger()));
        // Native .so ilk TRTC kullanımında yüklenir (ensureNativeLibrary).
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        mCloudManager.release();
    }
}