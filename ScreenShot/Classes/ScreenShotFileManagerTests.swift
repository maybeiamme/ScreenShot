//
//  ScreenShotFileManagerTests.swift
//  ScreenShotApp
//
//  Created by Jin Hyong Park on 18/4/17.
//  Copyright © 2017 PropertyGuru. All rights reserved.
//

import XCTest
@testable import PGScreenShot

class MockSessionIdController : PGScreenShotSessionIdProtocol {
    var recordingSession : String? = "R"
    var exportingSession : String? = "E"
    func exporting() {
        exportingSession = recordingSession
    }
    func exportFinished() {
        
    }
}

class MockSessionIdControllerForFlush : PGScreenShotSessionIdProtocol {
    var recordingSession : String? = "R"
    var exportingSession : String?
    func exporting() {
        exportingSession = recordingSession
    }
    func exportFinished() {
        
    }
}

class ScreenShotFileManagerTests: XCTestCase {
    
    override func setUp() {
        let sc = MockSessionIdControllerForFlush()
        CoreDataScreenShotFileManager.shared.flush(sessionIdController: sc)
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAddScreenShot() {
        let bundle = Bundle(for: ScreenShotFileManagerTests.self)
        let image = UIImage(named: "fake.png", in: bundle, compatibleWith: nil)
        let sc = MockSessionIdController()
        CoreDataScreenShotFileManager.shared.insert(image: image, timestamp: Date(), sessionIdController: sc)
        sc.exporting()
        let images = CoreDataScreenShotFileManager.shared.extractImages(sessionIdController: sc)
//        print( "images count : [\(images.count)]" )
        XCTAssert(images.count == 1)
    }
    
    func testFlushing() {
        var sc = MockSessionIdControllerForFlush()
        let bundle = Bundle(for: ScreenShotFileManagerTests.self)
        var images = Array<UIImage>()
        for i in 1 ... 98 {
            let image = UIImage(named: "giphy-\(i) (dragged).tiff", in: bundle, compatibleWith: nil)
            images.append(image!)
            CoreDataScreenShotFileManager.shared.insert(image: image, timestamp: Date(), sessionIdController: sc)
        }
        print( "images count : [\(images.count)]")
        sc.exporting()
        CoreDataScreenShotFileManager.shared.flush(sessionIdController: sc)
        sc = MockSessionIdControllerForFlush()
        let results = CoreDataScreenShotFileManager.shared.extractImages(sessionIdController: sc)
        XCTAssert(results.count == 0)
    }
    
    func testMultipleSCreenShotTest() {
        let sc = MockSessionIdControllerForFlush()
        sc.exporting()
        CoreDataScreenShotFileManager.shared.flush(sessionIdController: sc)

        let newsc = MockSessionIdController()
        let bundle = Bundle(for: ScreenShotFileManagerTests.self)
        for i in 1 ... 98 {
            let image = UIImage(named: "giphy-\(i) (dragged).tiff", in: bundle, compatibleWith: nil)
            CoreDataScreenShotFileManager.shared.insert(image: image, timestamp: Date(), sessionIdController: newsc)
        }
        newsc.exporting()
        let results = CoreDataScreenShotFileManager.shared.extractImages(sessionIdController: newsc)
        print( "results.count : [\(results.count)]")
        XCTAssert(results.count == 98)
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
