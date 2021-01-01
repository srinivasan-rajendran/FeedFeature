//
//  RemoteFeedItem.swift
//  FeedFeature
//
//  Created by Srinivasann Rajendran on 2020-12-25.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
