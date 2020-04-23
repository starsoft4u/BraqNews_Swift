//
//  Setting.swift
//  news
//
//  Created by Eliot Gravett on 2019/6/9.
//  Copyright © 2019 Barq. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Setting: Codable {
    var facebook: String?
    var twitter: String?
    var instagram: String?
    var linkedIn: String?
    var contactUsEmail: String?
    var suggestionEmail: String?
    var adsLastNews: Bool
    var adsNewspaper: Bool
    var adsMagazine: Bool
    var adsNewsDetail: Bool

    init() {
        facebook = nil
        twitter = nil
        instagram = nil
        linkedIn = nil
        contactUsEmail = nil
        suggestionEmail = nil
        adsLastNews = true
        adsNewspaper = true
        adsMagazine = true
        adsNewsDetail = true
    }

    init(json: JSON) {
        facebook = json["facebook"].string
        twitter = json["twitter"].string
        instagram = json["instagram"].string
        linkedIn = json["linkedin"].string
        contactUsEmail = json["contact_us_email"].string
        suggestionEmail = json["suggestion_email"].string
        adsLastNews = json["ads_last_news"].boolValue
        adsNewspaper = json["ads_newspaper"].boolValue
        adsMagazine = json["ads_magazine"].boolValue
        adsNewsDetail = json["ads_news_detail"].boolValue
    }
}
