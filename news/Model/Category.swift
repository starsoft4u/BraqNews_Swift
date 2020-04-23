//
//  Category.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Category {
    var id: Int = 0
    var channel: Int = 0
    var name: String?
    var iconUrl: String?
    var imageUrl: String?

    init(json: JSON) {
        id = json["id"].intValue
        channel = json["channel_id"].intValue
        name = json["name"].string
        iconUrl = json["icon_url"].string
        imageUrl = json["image_url"].string
    }
    
    init(id: Int = 0, name: String? = nil, iconUrl: String? = nil) {
        self.id = id
        self.name = name
        self.iconUrl = iconUrl
    }
}
