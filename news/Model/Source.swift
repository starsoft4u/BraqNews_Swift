//
//  Source.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Source {
    var id: Int = 0
    var name: String?
    var categoryId: Int = 0
    var imageUrl: String?
    var backgroundUrl: String?
    var description: String?
    var isMySource: Bool = false
    var followerCount: Int = 0

    init(json: JSON) {
        id = json["id"].intValue
        name = json["name"].string
        categoryId = json["categoryId"].intValue
        imageUrl = json["image_url"].string
        backgroundUrl = json["background_url"].string
        description = json["description"].string
        isMySource = json["checked"].boolValue
        followerCount = json["followers"].intValue
    }

    init(id: Int = 0, name: String? = nil) {
        self.id = id
        self.name = name
    }

    var follower: String {
        return followerCount == 1 ? "1 follower".localized : "% followers".localize(value: followerCount.description)
    }
}
