//
//  Exporter.swift
//  ScreenShotApp
//
//  Created by Jin Hyong Park on 24/4/17.
//  Copyright © 2017 Jin. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices
import AVFoundation

internal enum ExporterError: Error {
    case imageFilePathCreationError
    case cannotConvertDataToUIImageError
    case unabletoInitializeAVFoundationApi
}

internal typealias ExporterCompletionHanlder = (String) -> ()
internal typealias ExporterEmptyCompletionHanlder = () -> ()
internal typealias ExporterFailuerHanlder = (Error) -> ()

internal protocol Exporter {
    func export(from imageDatas: Array<Data>, completion: @escaping ExporterCompletionHanlder, failure: @escaping ExporterFailuerHanlder)
}

internal final class GifExporter : Exporter {
    internal func export(from imageDatas: Array<Data>, completion: @escaping ExporterCompletionHanlder, failure: @escaping ExporterFailuerHanlder) {
        let dispatchQueue = DispatchQueue(label: "com.jin.queue")
        dispatchQueue.sync {
            do {
                let path = try exportToFile(datas: imageDatas)
                completion(path)
            } catch let error {
                failure(error)
            }
        }
    }
    
    private func exportToFile(datas: Array<Data>) throws -> String {
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! as NSString).appendingPathComponent("result.gif")
        guard let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, kUTTypeGIF, datas.count, nil) else {
            throw ExporterError.imageFilePathCreationError
        }
        let numberProperties = NSDictionary(object: NSNumber(floatLiteral: 0.1), forKey: kCGImagePropertyGIFDelayTime as NSString )
        let frameProperties = NSDictionary( object: numberProperties, forKey: kCGImagePropertyGIFDictionary as NSString )
        let loopCount = NSDictionary(object: NSNumber(integerLiteral: 0), forKey: kCGImagePropertyGIFLoopCount as NSString )
        let gifProperties = NSDictionary(object: loopCount, forKey: kCGImagePropertyGIFDictionary as NSString)
        for data in datas {
            if let image = UIImage(data: data),
                let cgImage = image.cgImage {
                CGImageDestinationAddImage(destination, cgImage, frameProperties)
            }
        }
        
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary )
        CGImageDestinationFinalize(destination)
        return path
    }
}

internal final class MP4Exporter: Exporter {
    private let converter = ImagesToMP4()
    internal func export(from imageDatas: Array<Data>, completion: @escaping ExporterCompletionHanlder, failure: @escaping ExporterFailuerHanlder) {
        converter.convert(datas: imageDatas, completion: completion, failure: failure)
    }
}

private final class ImagesToMP4 {
    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private let semaphore = DispatchSemaphore(value: 1)
    
    fileprivate func convert(datas: Array<Data>, completion: @escaping ExporterCompletionHanlder, failure: @escaping ExporterFailuerHanlder) {
        guard let data = datas.first,
            let image = UIImage(data: data) else {
            failure(ExporterError.cannotConvertDataToUIImageError)
            return
        }
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! as NSString).appendingPathComponent("result.mp4")
        do {
            try initializeAVFoundationApi(image: image, path: path)
            writeToVideoWriter(datas: datas, completion: {
                completion(path)
            }, failure: failure)
        } catch {
            failure(error)
        }
    }
    
    private func initializeAVFoundationApi(image: UIImage, path: String) throws {
        let videoSize = image.size.video
        
        let avOutputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: NSNumber(value: Float(videoSize.width)),
            AVVideoHeightKey: NSNumber(value: Float(videoSize.height))
        ]
        
        let sourcePixelBufferAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(videoSize.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(videoSize.height))
        ]

        let outputUrl = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: outputUrl)
        
        videoWriter = try AVAssetWriter(outputURL: outputUrl, fileType: AVFileType.mp4)
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)
        
        guard let videoWriterInput = videoWriterInput,
            let videoWriter = videoWriter else {
            throw ExporterError.unabletoInitializeAVFoundationApi
        }
        videoWriter.add(videoWriterInput)
        
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: kCMTimeZero)
    }
    
    private func writeToVideoWriter(datas: Array<Data>, completion: @escaping ExporterEmptyCompletionHanlder, failure: @escaping ExporterFailuerHanlder) {
        var delay = (0.0 - 0.1) as TimeInterval
        let queue = DispatchQueue(label: "mediaInputQueue")
        guard let videoWriterInput = videoWriterInput,
            let videoWriter = videoWriter else {
            failure(ExporterError.unabletoInitializeAVFoundationApi)
            return
        }
        
        videoWriterInput.requestMediaDataWhenReady(on: queue) { [weak self] in
            self?.semaphore.wait()
            var finished = true
            for data in datas {
                if videoWriterInput.isReadyForMoreMediaData == false {
                    finished = false
                    break
                }
                delay += Double(0.1)
                if let image = UIImage(data: data) {
                    let presentationTime = CMTime(seconds: delay, preferredTimescale: 600)
                    do {
                        let _ = try self?.addImage(image: image, with : presentationTime)
                    } catch {
                        failure(error)
                        self?.semaphore.signal()
                        return
                    }
                }
            }
            
            if finished {
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting() { [weak self] in
                    self?.semaphore.signal()
                    completion()
                }
            } else {
                self?.semaphore.signal()
            }
        }
    }
    
    private func addImage(image : UIImage, with presentationTime : CMTime) throws -> Bool {
        guard let pixelBufferAdaptor = pixelBufferAdaptor,
            let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
            throw ExporterError.unabletoInitializeAVFoundationApi
        }
        guard let pixelBuffer = pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferPool, size: image.size.video) else {
            return false
        }
        return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    private func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer? {
        var pixelBufferOut: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            return nil
        }
        guard let pixelBuffer = pixelBufferOut else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context!.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
        
        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : -(newSize.width-size.width)/2
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : -(newSize.height-size.height)/2
        
        context!.draw(image.cgImage!, in: CGRect(x:x, y:y, width:newSize.width, height:newSize.height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        return pixelBuffer
    }
}

extension CGSize {
    fileprivate var video : CGSize {
        return CGSize(width: floor(self.width / 16) * 16, height: floor(self.height / 16) * 16)
    }
}
