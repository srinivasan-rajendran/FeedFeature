//
//  LocalFeedItem.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-25.
//

import Foundation

public struct LocalFeedItem: Equatable, Codable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL

    public init(id: UUID,
         description: String?,
         location: String?,
         imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}
