//
//  CodableFeedStore.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-27.
//

import Foundation

public class CodableFeedStore: FeedStore {

    private let storeURL: URL

    public init(storeURL: URL) {
        self.storeURL = storeURL
    }

    private struct Cache: Codable {
        let items: [CodableFeedItem]
        let date: Date
        var local: [LocalFeedItem] {
            return items.map { $0.localFeedItem }
        }
    }

    private let queue = DispatchQueue(label: "\(CodableFeedStore.self)Queue", qos: .userInitiated, attributes: .concurrent)

    private struct CodableFeedItem: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let imageURL: URL

        init(item: LocalFeedItem) {
            id = item.id
            description = item.description
            location = item.location
            imageURL = item.imageURL
        }

        var localFeedItem: LocalFeedItem {
            return LocalFeedItem(id: id, description: description, location: location, imageURL: imageURL)
        }
    }

    public func retrieveFeed(completion: @escaping RetrievalCompletion) {
        let storeURL = self.storeURL
        queue.async {
            guard let data = try? Data(contentsOf: storeURL) else {
                completion(.success(.none))
                return
            }
            do {
                let decoder = JSONDecoder()
                let cache = try decoder.decode(Cache.self, from: data)
                completion(.success(.some(CachedFeed(feed: cache.local, timestamp: cache.date))))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func insertFeed(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            completion(Result(catching: {
                let encoder = JSONEncoder()
                let encodedCache = try encoder.encode(Cache(items: items.map { CodableFeedItem.init(item: $0) }, date: timestamp))
                try encodedCache.write(to: storeURL)
            }))
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: storeURL.path) else {
                completion(.success(()))
                return
            }
            completion(Result(catching: {
                try FileManager.default.removeItem(at: storeURL)
            }))
        }
    }
}
