//
//  LocalFeedLoader.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-22.
//

import Foundation

public class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    private let calendar = Calendar(identifier: .gregorian)


    public typealias SaveResult = Error?
    public typealias LoadResult = FeedResult

    private var maxCacheAgeInDays: Int {
        return 7
    }

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items: items, completion: completion)
            }
        }
    }

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieveFeed { [unowned self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case let .found(items, timestamp) where validate(timestamp) :
                completion(.success(items.toModel()))
            case .empty, .found:
                completion(.success([]))
            }
        }
    }

    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCachAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return currentDate() < maxCachAge
    }

    private func cache(items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.insertFeed(items: items.toLocal(), timestamp: self.currentDate()) { [weak self] error in
            guard self != nil  else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] {
        return map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
    }
}

private extension Array where Element == LocalFeedItem {
    func toModel() -> [FeedItem] {
        return map { FeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
    }
}
