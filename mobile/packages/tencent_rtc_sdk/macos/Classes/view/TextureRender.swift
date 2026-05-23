//
//  TextureRender.swift
//  Pods
//
//  Created by vincepzhang on 2024/10/16.
//

import FlutterMacOS
import TXLiteAVSDK_TRTC_Mac
import Accelerate
import Dispatch

class TextureRender: NSObject, FlutterTexture, TRTCVideoRenderDelegate, V2TXLivePlayerObserver {
        
        
    private let registrar: FlutterPluginRegistrar
    private var channel: FlutterMethodChannel?
    
    private var latestPixelBuffer: CVPixelBuffer?
    
    private let textures: FlutterTextureRegistry
    private var textureId: Int64 = 0
    
    private var textureWidth: UInt32 = 0
    private var textureHeight: UInt32 = 0
    
    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        textures = registrar.textures
        super.init()
        textureId = textures.register(self)
        self.channel = FlutterMethodChannel(name: "tencent_rtc_texture_\(textureId)", binaryMessenger: registrar.messenger)
    }
    
    func getTextureId() -> Int64 {
        return textureId
    }
    
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if let buffer = latestPixelBuffer {
            return Unmanaged.passRetained(buffer)
        }
        return nil
    }

    // MARK: - TRTCVideoRenderDelegate
    public func onRenderVideoFrame( _ frame:TRTCVideoFrame, userId:String?, streamType:TRTCVideoStreamType){
        guard let nv12Buffer = frame.pixelBuffer else { return }
        if textureHeight != frame.height || textureWidth != frame.width {
            textureWidth = frame.width
            textureHeight = frame.height
            channel?.invokeMethod("updateVideoAspectRatio", arguments: ["width": textureWidth, "height": textureHeight])
        }
        latestPixelBuffer = nv12Buffer
        textures.textureFrameAvailable(textureId)
    }  

    // MARK: - V2TXLivePlayerObserver
    public func onRenderVideoFrame(_: any V2TXLivePlayerProtocol, frame videoFrame: V2TXLiveVideoFrame) {
        guard videoFrame.pixelFormat == V2TXLivePixelFormat.BGRA32, videoFrame.bufferType == V2TXLiveBufferType.nsData else {
            return
        }

        guard videoFrame.width > 0 && videoFrame.height > 0 else {
            return
        }

        let frameWidth = UInt32(videoFrame.width)
        let frameHeight = UInt32(videoFrame.height)
        
        guard let data = videoFrame.data else {
            return
        }
        
        let expectedSize = Int(frameWidth * frameHeight * 4)
        guard data.count >= expectedSize else {
            return
        }
        
        let nsData = data as NSData
        if let pixelBuffer = createPixelBufferFromBGRA32Data(data: nsData, width: Int(frameWidth), height: Int(frameHeight)) {
            latestPixelBuffer = pixelBuffer
            textures.textureFrameAvailable(textureId)
        }
    }

    // MARK: - Private Methods
    private func createPixelBufferFromBGRA32Data(data: NSData, width: Int, height: Int) -> CVPixelBuffer? {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let expectedDataSize = height * bytesPerRow
        
        guard data.length >= expectedDataSize else {
            print("Invalid data size for BGRA32: expected \(expectedDataSize), got \(data.length)")
            return nil
        }

        var pixelBuffer: CVPixelBuffer?
        
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferBytesPerRowAlignmentKey as String: 64,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        let lockFlags: CVPixelBufferLockFlags = []
        let lockStatus = CVPixelBufferLockBaseAddress(buffer, lockFlags)
        guard lockStatus == kCVReturnSuccess else {
            return nil
        }

        defer {
            CVPixelBufferUnlockBaseAddress(buffer, lockFlags)
        }

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            return nil
        }

        let actualBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        
        if actualBytesPerRow != bytesPerRow {
            let sourcePtr = data.bytes.assumingMemoryBound(to: UInt8.self)
            let destPtr = baseAddress.assumingMemoryBound(to: UInt8.self)

            for row in 0 ..< height {
                let sourceRowPtr = sourcePtr + (row * bytesPerRow)
                let destRowPtr = destPtr + (row * actualBytesPerRow)
                memcpy(destRowPtr, sourceRowPtr, bytesPerRow)
            }
        } else {
            memcpy(baseAddress, data.bytes, expectedDataSize)
        }

        return buffer
    }
}
