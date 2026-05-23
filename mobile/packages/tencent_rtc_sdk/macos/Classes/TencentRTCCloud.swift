//
//  TencentRTCCloud.swift
//  tencent_rtc_ffi
//
//  Created by vincepzhang on 2024/9/19.
//

import Cocoa
import FlutterMacOS
import TXLiteAVSDK_TRTC_Mac

public class TencentRTCCloud: NSObject, FlutterPlugin {
    
    private let channel: FlutterMethodChannel
    private var textureMap: [Int64: TextureRender] = [:]
    private let registrar: FlutterPluginRegistrar
    
    init(registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "TencentRTCffi", binaryMessenger: registrar.messenger)
        self.registrar = registrar
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = TencentRTCCloud(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: instance.channel)
        
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        switch call.method {
        case "initialize":
            TRTCCloud.sharedInstance()
            result(0)
        case "createTextureView":
            createTextureView(call: call, result: result)
        case "disposeTextureView":
            disposeTextureView(call: call, result: result)
        case "startLocalPreview":
            startLocalPreview(call: call, result: result)
        case "startRemoteView":
            startRemoteView(call: call, result: result)
        case "stopLocalPreview":
            stopLocalPreview(call: call, result: result)
        case "stopRemoteView":
            stopRemoteView(call: call, result: result)
        case "updateLocalView":
            updateLocalView(call: call, result: result)
        case "updateRemoteView":
            updateRemoteView(call: call, result: result)
        case "getCustomVideoFrameListener":
            getCustomVideoFrameListener(call: call, result: result)
        case "getTextureId":
            getTextureId(result: result)
        case "getSurfaceId":
            result(0)
        case "unregisterTexture":
            unregisterTexture(call: call, result: result)
        case "setTextureBufferSize":
            result(0)
        default:
            print("TRTCPlugin onCallMethod \(call.method) is not impl")
            result(0)
        }
    }
    
    private func createTextureView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let textureRender = TextureRender(registrar: registrar)
        let textureId = textureRender.getTextureId()
        textureMap[textureId] = textureRender
        result(textureId)
    }
    
    private func disposeTextureView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let textureId = Utils.getParamByKey(call: call, result: result, param: "textureId") as? Int64 {
            textureMap.removeValue(forKey: textureId)
        }
        result(0)
    }
    
    private func startLocalPreview(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let viewId = Utils.getParamByKey(call: call, result: result, param: "viewId") as? Int64 else { return }

        guard let textureRender = textureMap[viewId] else { return }
        TRTCCloud.sharedInstance().startLocalPreview(nil)
        TRTCCloud.sharedInstance().setLocalVideoRenderDelegate(textureRender, pixelFormat: TRTCVideoPixelFormat._32BGRA, bufferType: TRTCVideoBufferType.pixelBuffer)
        result(0)
    }
    
    private func startRemoteView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let streamType = Utils.getParamByKey(call: call, result: result, param: "streamType") as? Int else { return }
        guard let viewId = Utils.getParamByKey(call: call, result: result, param: "viewId") as? Int64 else { return }
        guard let userId = Utils.getParamByKey(call: call, result: result, param: "userId") as? String else { return }
        guard let textureRender = textureMap[viewId] else { return }
        
        TRTCCloud.sharedInstance().startRemoteView(userId, streamType: TRTCVideoStreamType(rawValue: streamType) ?? .big, view: nil)
        TRTCCloud.sharedInstance().setRemoteVideoRenderDelegate(userId, delegate: textureRender, pixelFormat:  TRTCVideoPixelFormat._32BGRA, bufferType: TRTCVideoBufferType.pixelBuffer)
        result(0)
    }
    
    private func stopLocalPreview(call: FlutterMethodCall, result: @escaping FlutterResult) {
        TRTCCloud.sharedInstance().stopLocalPreview()
        TRTCCloud.sharedInstance().setLocalVideoRenderDelegate(nil, pixelFormat: TRTCVideoPixelFormat._32BGRA, bufferType: TRTCVideoBufferType.pixelBuffer)

        result(0)
    }
    
    private func stopRemoteView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let streamType = Utils.getParamByKey(call: call, result: result, param: "streamType") as? Int else { return }
        guard let userId = Utils.getParamByKey(call: call, result: result, param: "userId") as? String else { return }
        
        TRTCCloud.sharedInstance().stopRemoteView(userId, streamType: TRTCVideoStreamType(rawValue: streamType) ?? .big)
        TRTCCloud.sharedInstance().setRemoteVideoRenderDelegate(userId, delegate: nil, pixelFormat:  TRTCVideoPixelFormat._32BGRA, bufferType: TRTCVideoBufferType.pixelBuffer)
        result(0)
    }
    
    private func updateLocalView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let viewId = Utils.getParamByKey(call: call, result: result, param: "viewId") as? Int64 else { return }

        guard let textureRender = textureMap[viewId] else { return }
        
        TRTCCloud.sharedInstance().updateLocalView(nil)
        TRTCCloud.sharedInstance().setLocalVideoRenderDelegate(textureRender, pixelFormat: TRTCVideoPixelFormat._32BGRA, bufferType: TRTCVideoBufferType.pixelBuffer)
        result(0)
    }

    private func updateRemoteView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let streamType = Utils.getParamByKey(call: call, result: result, param: "streamType") as? Int else { return }
        guard let viewId = Utils.getParamByKey(call: call, result: result, param: "viewId") as? Int64 else { return }
        guard let userId = Utils.getParamByKey(call: call, result: result, param: "userId") as? String else { return }
        
        guard let textureRender = textureMap[viewId] else { return }
        
        TRTCCloud.sharedInstance().updateRemoteView(nil, streamType: TRTCVideoStreamType(rawValue: streamType) ?? .big, forUser: userId)
        TRTCCloud.sharedInstance().setRemoteVideoRenderDelegate(userId, delegate: textureRender, pixelFormat:  TRTCVideoPixelFormat._32BGRA, bufferType: TRTCVideoBufferType.pixelBuffer)
        result(0)
    }

    private func getCustomVideoFrameListener(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let textureId = arguments["textureId"] as? Int64
        else {
            debugPrint("TencentLiveCloud: ERROR - Invalid arguments for getCustomVideoFrameListener")
            result(0)
            return
        }

        guard let observer = textureMap[textureId] else {
            debugPrint("TencentLiveCloud: ERROR - No observer found for textureId: \(textureId)")
            result(0)
            return
        }

        let observerPtr = Unmanaged.passUnretained(observer).toOpaque()
        let ptrValue = Int(bitPattern: observerPtr)
        result(ptrValue)
    }

    private func getTextureId(result: @escaping FlutterResult) {
        if let existingTextureId = textureMap.keys.first {
            debugPrint("TencentLiveCloud: Reusing existing textureId: \(existingTextureId)")
            result(existingTextureId)
            return
        }
        let textureRender = TextureRender(registrar: registrar)
        let textureId = textureRender.getTextureId()
        textureMap[textureId] = textureRender
        result(textureId)
    }

    private func unregisterTexture(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let textureId = arguments["textureId"] as? Int64
        else {
            debugPrint("TencentLiveCloud: ERROR - Invalid arguments for unregisterTexture")
            result(FlutterError(code: "INVALID_ARGUMENT", message: "textureId is required", details: nil))
            return
        }
        
        if let textureRender = textureMap.removeValue(forKey: textureId) {
            registrar.textures.unregisterTexture(textureId)
        }

        result(nil)
    }
}
