//
//  FeedAPI.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-16.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void)
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalid
    }

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (RemoteFeedLoader.Error) -> Void) {
        client.get(from: url) { error, response in
            guard let _ = response else {
                completion(.connectivity)
                return
            }
            completion(.invalid)
        }
    }
}
