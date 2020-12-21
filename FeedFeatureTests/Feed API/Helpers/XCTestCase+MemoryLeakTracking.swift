//
//  XCTestCase+MemoryLeakTracking.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-20.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak", file: file, line: line)
        }
    }
}
