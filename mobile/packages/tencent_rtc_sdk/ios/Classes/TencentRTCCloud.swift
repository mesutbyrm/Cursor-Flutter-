//
//  TencentRTCCloud.swift
//  tencent_rtc_ffi
//
//  Created by iveshe on 2024/9/19.
//

import Flutter
import Foundation
import TXLiteAVSDK_Professional
import TXCustomBeautyProcesserPlugin

public class TencentRTCCloud: NSObject, FlutterPlugin {
    private static var customBeautyProcesserFactory: ITXCustomBeautyProcesserFactory? = nil
    private static let beautyQueue = DispatchQueue(label: "live_beauty_queue")
    
    private static var cloudManager: TRTCCloudManager?
    @objc public static var sObserver: V2TXLivePusherObserver?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "TencentRTCffi", binaryMessenger: registrar.messenger())
        cloudManager = TRTCCloudManager(channel: channel)
        
        let viewFactory = TRTCPlatformViewFactory(message: registrar.messenger())
        registrar.register(viewFactory,withId: "TRTCPlatformView")
    }
    
    public static func getBeautyProcesserFactory() -> ITXCustomBeautyProcesserFactory? {
        var result: ITXCustomBeautyProcesserFactory?
            beautyQueue.sync {
                result = self.customBeautyProcesserFactory
            }
        return result
    }
    
    @objc public static func setBeautyProcesserFactory(factory: ITXCustomBeautyProcesserFactory) {
        customBeautyProcesserFactory = factory
    }
}
