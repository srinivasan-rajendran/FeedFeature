//
//  FeedItem.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-15.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
