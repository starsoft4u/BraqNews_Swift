//
//  Comment.swift
//  news
//
//  Created by Eliot Gravett on 2019/6/8.
//  Copyright © 2019 Barq. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Comment {
    var id: Int
    var userId: Int
    var userName: String?
    var userPhoto: String?
    var comment: String?
    var liked: [Int]
    var disliked: [Int]
    var flagged: [Int]
    var issuedAt: Int

    init(json: JSON) {
        id = json["id"].intValue
        userId = json["user_id"].intValue
        userName = json["username"].string
        userPhoto = json["userPhoto"].string
        comment = json["comment"].string
        liked = json["liked"].stringValue.split(separator: ",").map { Int($0) ?? 0 }
        disliked = json["disliked"].stringValue.split(separator: ",").map { Int($0) ?? 0 }
        flagged = json["flagged"].stringValue.split(separator: ",").map { Int($0) ?? 0 }
        issuedAt = Int(json["issued_at"].stringValue.toDate()!.timeIntervalSince1970) * 1000
    }
}
