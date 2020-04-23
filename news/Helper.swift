//
//  Helper.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/22.
//  Copyright © 2019 Barq. All rights reserved.
//

import FirebaseInstanceID
import FirebaseMessaging
import Networking
import SwiftDate
import SwiftyJSON
import UIKit

enum AppStoryboard: String {
    case Main

    var instance: UIStoryboard {
        return UIStoryboard(name: rawValue, bundle: Bundle.main)
    }

    func viewController<T: UIViewController>(_ viewControllerClass: T.Type) -> T {
        let storyboardIdentifier = (viewControllerClass as UIViewController.Type)
        return instance.instantiateViewController(withIdentifier: "\(storyboardIdentifier)") as! T
    }
}

final class Defaults {
    struct lang: TSUD {
        static let defaultValue: String = "ar"
    }

    struct apiToken: TSUD {
        static let defaultValue: String? = nil
    }

    struct userId: TSUD {
        static let defaultValue: Int = 0
    }

    struct userName: TSUD {
        static let defaultValue: String? = nil
    }

    struct email: TSUD {
        static let defaultValue: String? = nil
    }

    struct photo: TSUD {
        static let defaultValue: String? = nil
    }

    struct notifyGlobal: TSUD {
        static let defaultValue: Bool = true
    }

    struct notifySound: TSUD {
        static let defaultValue: String? = nil
    }

    struct setting: TSUD {
        static var defaultValue: Setting = Setting()
    }

    struct sources: TSUD {
        static var defaultValue: [Int] = []
    }

    struct notifications: TSUD {
        static var defaultValue: [Int] = []
    }

    struct favorites: TSUD {
        static var defaultValue: [Int] = []
    }
}

final class Constants {
    static let adsUnitId = "ca-app-pub-1137588610425183/1864314730"
    struct Url {
//        static let api = "http://192.168.0.102:88/barqnews/src/BarqNewsApi/api"
        static let api = "https://barq.news/BarqNewsApi/api"
    }

    struct Font {
        public static let regular = UIFont(name: "HelveticaNeueW23forSKY-Reg", size: 14)!
    }
}

extension Int {
    var diffString: String? {
        var str: String?
        let date = Date(milliseconds: self)
        let diff = (Date() - date).timeInterval
        if diff >= 1.weeks.timeInterval {
            let region = Region(calendar: Calendars.gregorian, zone: Zones.asiaRiyadh, locale: Locales.arabicSaudiArabia)
            str = DateInRegion(date, region: region).toFormat("dd MMM yyyy")
        } else if diff >= 1.days.timeInterval {
            let day = Int(diff / 86400)
            str = day == 1 ? "1 day ago".localized :"% days ago".localize(value: day.description)
        } else if diff >= 1.hours.timeInterval {
            let hour = Int(diff / 3600)
            str = hour == 1 ? "1 hour ago".localized : "% hours ago".localize(value: hour.description)
        } else if diff >= 1.minutes.timeInterval {
            let min = Int(diff / 60)
            str = min == 1 ? "1 minute ago".localized : "% minutes ago".localize(value: min.description)
        } else {
            str = "Just ago".localized
        }
        return str
    }
}

func subscribeNotification(topic: String?, subscribe: Bool) {
    guard Defaults.notifyGlobal.value, let topic = topic else {
        return
    }

    if subscribe {
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("Subscribed failed to \(topic) with \(error)")
            } else {
                print("Subscribed success to \(topic)!")
            }
        }
    } else {
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                print("Subscribed failed from \(topic) with \(error)")
            } else {
                print("Subscribed success from \(topic)!")
            }
        }
    }
}

func unsubscribeNotification() {
    Defaults.notifications.value.forEach {
        Messaging.messaging().unsubscribe(fromTopic: $0.description)
    }

    DispatchQueue.global().async {
        InstanceID.instanceID().deleteID { error in
            if let error = error {
                print("Delete instance id failed \(error)")
            } else {
                print("Delete instance id successfully!")
            }
        }
    }
}
