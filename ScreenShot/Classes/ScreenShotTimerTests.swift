//
//  ScreenShotTimerTests.swift
//  ScreenShotApp
//
//  Created by Jin Hyong Park on 18/4/17.
//  Copyright © 2017 PropertyGuru. All rights reserved.
//

import XCTest
@testable import PGScreenShot

class ScreenShotTimerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testTimerWork() {
        var value = 0
        PGScreenShotTimer.shared.todoForEveryXSeconds = {
            value += 1
        }
        PGScreenShotTimer.shared.run()
        
        let expect = expectation(description: "value should over 6")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssert(value > 6)
            expect.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.5) { (error) in
            
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
