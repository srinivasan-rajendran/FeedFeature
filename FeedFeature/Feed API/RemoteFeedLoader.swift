//
//  FeedAPI.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-16.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL)
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load() {
        client.get(from: url)
    }
}
