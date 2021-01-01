//
//  SharedTestHelpers.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-25.
//

import Foundation

func anyURL() -> URL {
    return URL(string: "https://example.com")!
}

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}
