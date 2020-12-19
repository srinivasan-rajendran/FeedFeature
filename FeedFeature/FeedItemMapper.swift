//
//  FeedItemMapper.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-19.
//

import Foundation

internal class FeedItemsMapper {

    private struct Root: Decodable {
        let items: [Item]
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL

        var item: FeedItem {
            return FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }

    private static var OK_200 = 200

    internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        return try JSONDecoder().decode(Root.self, from: data).items.map { $0.item }
    }
}
