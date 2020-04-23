//
//  ViewController.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/22.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit

class MainVC: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        viewControllers = [
            subViewController(title: "Last News".localized, image: #imageLiteral(resourceName: "ic_news.png"), viewController: NewsVC()),
            subViewController(title: "News Paper".localized, image: #imageLiteral(resourceName: "ic_newspaper"), viewController: CategoryVC()),
            subViewController(title: "Magazine".localized, image: #imageLiteral(resourceName: "ic_magazine"), viewController: MagazineVC()),
            subViewController(title: "My News".localized, image: #imageLiteral(resourceName: "ic_mynews"), viewController: MyNewsVC()),
            subViewController(title: "Setting".localized, image: #imageLiteral(resourceName: "ic_setting"), viewController: AppStoryboard.Main.viewController(SettingVC.self)),
        ]

        loadSettings()
    }

    func loadSettings() {
        get(url: "/settings", indicator: false) { res in
            Defaults.setting.value = Setting(json: res)
        }
    }

    fileprivate func subViewController(title: String?, image: UIImage?, viewController: UIViewController) -> UIViewController {
        let vc = UINavigationController(rootViewController: viewController)
        vc.tabBarItem = UITabBarItem(title: title, image: image, tag: 0)
        vc.navigationBar.isTranslucent = false
        vc.navigationBar.barTintColor = .primaryColor
        vc.navigationBar.tintColor = .white
        vc.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
        ]
        return vc
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tabBar.isTranslucent = false
        tabBar.tintColor = .white
        tabBar.barTintColor = .darkGreyColor

        // Tabbar item selected background
        let itemCount = CGFloat(tabBar.items?.count ?? 1)
        let tabSize = CGSize(width: tabBar.frame.width / itemCount, height: tabBar.frame.height)

        UIGraphicsBeginImageContext(tabSize)
        #imageLiteral(resourceName: "tab_bg").draw(in: CGRect(x: 0, y: 0, width: tabSize.width, height: tabSize.height))
        let selBg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        tabBar.selectionIndicatorImage = selBg
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let index = tabBar.items?.firstIndex(of: item),
            let navVC = viewControllers?[index] as? UINavigationController else { return }

        navVC.popToRootViewController(animated: false)

        if let vc = navVC.topViewController as? NewsVC {
            vc.loadData()
        } else if let vc = navVC.topViewController as? CategoryVC {
            vc.loadData()
        } else if let vc = navVC.topViewController as? MagazineVC {
            vc.loadData()
        } else if let vc = navVC.topViewController as? MyNewsVC {
            vc.loadData()
        } else if let vc = navVC.topViewController as? SettingVC {
            vc.loadData()
        }
    }
}

