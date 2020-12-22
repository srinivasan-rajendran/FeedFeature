//
//  LocalFeedLoader.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-22.
//

import Foundation

public class LocalFeedLoader {
    let store: FeedStore
    let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items: items, completion: completion)
            }
        }
    }

    private func cache(items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.insertFeed(items: items, timestamp: self.currentDate()) { [weak self] error in
            guard self != nil  else { return }
            completion(error)
        }
    }
}
