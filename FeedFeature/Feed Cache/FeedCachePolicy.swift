//
//  FeedCachePolicy.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-26.
//

import Foundation

internal final class FeedCachePolicy {

    private init() {}
    
    private static let calendar = Calendar(identifier: .gregorian)

    private static var maxCacheAgeInDays: Int {
        return 7
    }

    internal static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCachAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return date < maxCachAge
    }

}
