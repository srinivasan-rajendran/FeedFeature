//
//  FeedCacheTestHelpers.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-25.
//

import Foundation
import FeedFeature


func uniqueItems() -> (models: [FeedItem], local: [LocalFeedItem]) {
    let items = [uniqueItem(), uniqueItem()]
    let local = items.map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
    return (items, local)
}

func uniqueItem() -> FeedItem {
    return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
}

extension Date {

    private var feedCacheAgeInDays: Int {
        return 7
    }

    func minusFeedCacheMaxAge() -> Date {
        return self.adding(days: -feedCacheAgeInDays)
    }

    private func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}

extension Date {

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
