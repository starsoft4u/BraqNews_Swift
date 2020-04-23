//
//  News.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

struct News {
    var source: Source
    var id: Int
    var time: Int
    var title: String?
    var image: String?
    var imageRatio: CGFloat
    var url: String?
    var comment: Int
    var favorited: Bool

    init(json: JSON) {
        source = Source(json: json["source"]);
        id = json["id"].intValue
        title = json["title"].string
        time = json["issued_at"].intValue
        image = json["image_url"].string
        imageRatio = CGFloat(json["image_ratio"].doubleValue)
        url = json["url"].string
        comment = json["comment"].intValue
        favorited = json["favorited"].boolValue
    }
}
