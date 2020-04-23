//
//  AppDelegate.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/22.
//  Copyright © 2019 Barq. All rights reserved.
//

import FBSDKCoreKit
import Firebase
import GoogleSignIn
import IQKeyboardManagerSwift
import Localize
import TwitterKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Keyboard
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 12

        // Searchbar
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UISearchBar.appearance().tintColor = .white

        // Tabbar
        UITabBarItem.appearance().setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.greyColor,
            NSAttributedString.Key.font: Constants.Font.regular.withSize(12),
        ], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)

        // Localization
        Localize.update(provider: .json)
        Localize.update(fileName: "lang")
        Localize.update(defaultLanguage: "ar")

        // Facebook
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

        // Firebase
        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        // Google
        GIDSignIn.sharedInstance()?.clientID = "536927021336-v24dk4iqea63k6pmasdpmb3mh3at90b2.apps.googleusercontent.com"

        // Twitter
        TWTRTwitter.sharedInstance().start(withConsumerKey: "FxV6fZynvvv2DUIP1uS8YWYJP", consumerSecret: "MI8HOByBMIDVtCT1gxFQv6EEw7CYFnlclcrEHiFagQqNSTD20U")

        // Initialize the Google Mobile Ads SDK.
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        if window == nil {
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        // FCM
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        application.registerForRemoteNotifications()

        let mainVC = MainVC()
        if let dict = launchOptions?[.remoteNotification] as? [String: Any], let id = dict["newsId"] as? String {
            let nav = mainVC.viewControllers?.first as? UINavigationController
            let newsVC = NewsDetailVC()
            newsVC.newsId = id
            nav?.pushViewController(newsVC, animated: true)
        }

        window?.rootViewController = mainVC
        window?.makeKeyAndVisible()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let fb = ApplicationDelegate.shared.application(app, open: url, options: options)
        let google = GIDSignIn.sharedInstance().handle(
            url as URL?,
            sourceApplication: options[.sourceApplication] as? String,
            annotation: options[.annotation]
        )
        let twitter = TWTRTwitter.sharedInstance().application(app, open: url, options: options)
        return fb || google || twitter
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("[$] Did register for notification with token >>> \(deviceToken)")
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[$] Failed to register for notification with error : \(error.localizedDescription)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("[$] Notification did receive response >>> \(userInfo)")

        if let id = userInfo["newsId"] as? String {
            let newsVC = NewsDetailVC()
            newsVC.newsId = id

            let mainVC = window?.rootViewController as? MainVC
            mainVC?.selectedIndex = 0
            let nav = mainVC?.viewControllers?.first as? UINavigationController
            nav?.popToRootViewController(animated: false)
            nav?.pushViewController(newsVC, animated: true)
        }

        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("[$] Notification will present with >>> \(userInfo)")

        Messaging.messaging().appDidReceiveMessage(userInfo)

        completionHandler([.sound, .alert, .badge])
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("[$] Did receive FCMToken >>> \(fcmToken)")

        if Defaults.notifyGlobal.value {
            Defaults.notifications.value.forEach {
                subscribeNotification(topic: $0.description, subscribe: true)
            }
        }
    }

    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        let userInfo = remoteMessage.appData
        print("[$] Did receive remote message >>> \(userInfo)")
    }
}
