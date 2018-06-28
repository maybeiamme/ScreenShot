//
//  Capture.swift
//  ScreenShotApp
//
//  Created by Jin Hyong Park on 18/4/17.
//  Copyright © 2017 Jin. All rights reserved.
//

import UIKit

enum CaptureError: Error {
    case failedToGetCurrentImageContext
    case failedToObtainTopMostView
}

internal protocol Capture {
    func take(scale: CGFloat) throws -> UIImage
}

internal final class CaptureWithViewHierarchy: Capture {
    func take(scale: CGFloat = 0.5) throws -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width * scale, height: UIScreen.main.bounds.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0);
        UIApplication.shared.keyWindow?.drawHierarchy(in: rect, afterScreenUpdates: false)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            throw CaptureError.failedToGetCurrentImageContext
        }
        UIGraphicsEndImageContext()
        return image
    }
}

internal final class CaptureWithGraphicContext: Capture {
    func take(scale: CGFloat = 0.5) throws -> UIImage {
        guard let window = UIApplication.shared.keyWindow else {
            throw CaptureError.failedToObtainTopMostView
        }
        let rect = window.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            throw CaptureError.failedToGetCurrentImageContext
        }
        window.layer.render(in: context)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            throw CaptureError.failedToGetCurrentImageContext
        }
        UIGraphicsEndImageContext()
        return image
    }
}
