//
//  Notification.swift
//  news
//
//  Created by Eliot Gravett on 2019/6/8.
//  Copyright © 2019 Barq. All rights reserved.
//

import Foundation

public extension Notification.Name {
    static let commentChanged = Notification.Name("comment_changed")
    static let favoriteChanged = Notification.Name("favorite_changed")
    static let followChanged = Notification.Name("follow_changed")
}
