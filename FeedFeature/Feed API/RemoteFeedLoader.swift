//
//  FeedAPI.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-16.
//

import Foundation

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public enum Result: Equatable {
        case success([FeedItem])
        case failure(RemoteFeedLoader.Error)
    }

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (RemoteFeedLoader.Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success(let data, let response):
                completion(self.map(data, response))
            case .failure:
                completion(.failure(.connectivity))
            }

        }
    }

    private func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        do {
            let items = try FeedItemsMapper.map(data, response)
            return .success(items)
        } catch {
           return .failure(.invalidData)
        }
    }
}
