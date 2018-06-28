//
//  Recorder.swift
//  ScreenShotApp
//
//  Created by Jin Hyong Park on 18/4/17.
//  Copyright © 2017 Jin. All rights reserved.
//

import UIKit
import MessageUI

@available(iOS 10.0, *)
public class Recorder : NSObject {
    static public let shared = Recorder()
    
    private let capture: Capture
    private let exporter: Exporter
    private let storage: PersistentStorage
    private var timer: Timer?
    private var currentSession: String = ""
    
    private override init() {
        capture = CaptureWithGraphicContext()
        storage = MemoryPersistentStorage()
        exporter = MP4Exporter()
    }
    
    public func record() {
        NotificationCenter.default.addObserver(self, selector: #selector(Recorder.appDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Recorder.appDidEnterForeground), name: .UIApplicationDidBecomeActive, object: nil)
        currentSession = generateSessionId()
        startRecord()
    }
    
    public func stop() {
        NotificationCenter.default.removeObserver(self)
        stopRecord()
    }
    
    public func export() {
        try? storage.datas(for: currentSession, completion: { [weak self] (data) in
            self?.exporter.export(from: data, completion: { (path) in
                
            }, failure: { (error) in
                
            })
        }, failure: { (error) in
            
        })
        
    }
    
    @objc public func appDidEnterBackground() {
        stopRecord()
    }
    
    @objc public func appDidEnterForeground() {
        startRecord()
    }
    
    private func startRecord() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (t) in
            do {
                if let image = try self?.capture.take(scale: 0.5),
                    let data = UIImageJPEGRepresentation(image, 0.1),
                    let currentSessionId = self?.currentSession {
                    self?.storage.insert(data: data, sessionId: currentSessionId)
                }
            } catch {
                print("error caught in record")
                print(error)
            }
        }
    }
    
    private func stopRecord() {
        timer?.invalidate()
        timer = nil
    }
    
    private func generateSessionId() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomLength = UInt32(letters.count)

        let randomString: String = (0 ..< 10).reduce(String()) { accum, _ in
            let randomOffset = arc4random_uniform(randomLength)
            let randomIndex = letters.index(letters.startIndex, offsetBy: Int(randomOffset))
            return accum.appending(String(letters[randomIndex]))
        }

        return randomString
    }
}
