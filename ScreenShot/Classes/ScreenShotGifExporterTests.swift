//
//  ScreenShotGifExporterTests.swift
//  PGScreenShot
//
//  Created by Jin Hyong Park on 27/4/17.
//  Copyright © 2017 PropertyGuru. All rights reserved.
//

import XCTest
@testable import PGScreenShot

class ScreenShotGifExporterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExporterWorkProperly() {
        let fm = MockPGScreenShotFileManager()
        let path = ScreenShotGifExporter.exportToFile(in: fm)
        XCTAssertNotNil(path, "path should not be nil")
    }
    
    func testExportGifWithCompletionHandler() {
        let fm = MockPGScreenShotFileManager()
        let ex = expectation(description: "file successfully extracted failed")
        ScreenShotGifExporter.exportToFile(in: fm) { (path) in
            print( path )
            XCTAssertNotNil(path, "path should not be nil" )
            ex.fulfill()
        }
        waitForExpectations(timeout: 6.0) { (error) in
            
        }
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
