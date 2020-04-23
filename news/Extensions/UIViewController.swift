//
//  UIViewController.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import Networking
import NVActivityIndicatorView
import SwiftEntryKit
import SwiftyJSON
import UIKit

// MARK: - UITableView

extension UIViewController {
    func setup<T: UITableViewCell>(_ tableView: UITableView, cellClass: [T.Type] = [], pullToRefresh: Bool = false, separator: Bool = false) {
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.separatorStyle = separator ? .singleLine : .none
        tableView.backgroundColor = .bgColor
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false

        cellClass.forEach {
            let nib = UINib(nibName: $0.nibName, bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: $0.identifier)
        }

        if pullToRefresh {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(onPullRefresh), for: .valueChanged)
            tableView.refreshControl = refreshControl
        }
    }

    @objc func onPullRefresh() {}
}

// MARK: - Alert

extension UIViewController {
    func toast(_ message: String, success: Bool = true) {
        let title = EKProperty.LabelContent(text: "", style: .init(font: UIFont.systemFont(ofSize: 20), color: success ? .black : .white))
        let description = EKProperty.LabelContent(
            text: message.localized,
            style: .init(font: UIFont.systemFont(ofSize: 17), color: success ? .black : .white, alignment: .left))

        let simpleMessage = EKSimpleMessage(title: title, description: description)
        let notificationMessage = EKNotificationMessage(simpleMessage: simpleMessage)
        let contentView = EKNotificationMessageView(with: notificationMessage)

        var attributes = EKAttributes()
        attributes.windowLevel = .statusBar
        attributes.screenBackground = .clear
        attributes.entryBackground = success ? .color(color: UIColor(rgb: 0x008F00)) : .color(color: .primaryColor)
        attributes.roundCorners = .none
        attributes.scroll = .enabled(swipeable: false, pullbackAnimation: .jolt)
        attributes.border = .none
        attributes.entranceAnimation = .init(translate: .init(duration: 0.2, anchorPosition: .top))
        attributes.exitAnimation = .init(translate: .init(duration: 0.2, anchorPosition: .top))
        attributes.position = .top
        attributes.positionConstraints.safeArea = .empty(fillSafeArea: true)
        attributes.positionConstraints.verticalOffset = 0
        attributes.positionConstraints.size = .screen
        attributes.displayDuration = 2
        attributes.precedence = .enqueue(priority: EKAttributes.Precedence.Priority.max)

        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    func success(_ message: String) {
        toast(message)
    }

    func fail(_ message: String, for control: UIView? = nil) {
        toast(message, success: false)
        control?.becomeFirstResponder()
    }
}

// MARK: - Activity indicator

extension UIViewController: NVActivityIndicatorViewable {}

// MARK: - Networking

extension UIViewController {
    fileprivate func handleResponse(url: String, result: JSONResult, completion: ((_ res: JSON) -> Void)?) {
        switch result {
        case .success(let res):
            print("[$] Response [\(url)] success")
            let json = JSON(res.dictionaryBody)
            if json["success"].bool == true {
                completion?(json["data"])
            } else {
                fail(json["error"].string ?? "Something went wrong.".localized)
            }

        case .failure(let res):
            print("[$] response [\(url)] Failed : \(res.error)")
            switch res.error.code {
            case 401:
                fail("You have to login or signup".localized)
                logout()
            case 400:
                let json = JSON(res.dictionaryBody)
                fail(json["error"].stringValue)
            default:
                fail(res.error.localizedDescription)
            }
        }
    }

    func get(
        url: String,
        params: [String: Any]? = nil,
        indicator: Bool = true,
        refreshControl: UIRefreshControl? = nil,
        completion: ((_ res: JSON) -> Void)? = nil) {
        if indicator, !isAnimating {
            startAnimating()
        }

        print("[$] GET: \(url) Parameter: \(params?.debugDescription ?? "[]")")

        let net: Networking = Networking(baseURL: Constants.Url.api)
        if let token = Defaults.apiToken.value {
            net.setAuthorizationHeader(headerKey: "Authentication", headerValue: token)
        }
        net.get(url, parameters: params) { result in
            if indicator, self.isAnimating {
                self.stopAnimating()
            }
            refreshControl?.endRefreshing()
            self.handleResponse(url: url, result: result, completion: completion)
        }
    }

    func post(
        url: String,
        params: [String: Any]? = nil,
        paramType: Networking.ParameterType = .formURLEncoded,
        parts: [FormDataPart] = [],
        indicator: Bool = true,
        refreshControl: UIRefreshControl? = nil,
        completion: ((_ res: JSON) -> Void)? = nil) {
        if indicator, !isAnimating {
            startAnimating()
        }

        print("[$] POST: \(url) Parameter: \(params?.debugDescription ?? "[]")")

        let net: Networking = Networking(baseURL: Constants.Url.api)
        if let token = Defaults.apiToken.value {
            net.setAuthorizationHeader(headerKey: "Authentication", headerValue: token)
        }
        if parts.isEmpty {
            net.post(url, parameterType: paramType, parameters: params) { result in
                if indicator, self.isAnimating {
                    self.stopAnimating()
                }
                refreshControl?.endRefreshing()
                self.handleResponse(url: url, result: result, completion: completion)
            }
        } else {
            net.post(url, parameters: params, parts: parts) { result in
                if indicator, self.isAnimating {
                    self.stopAnimating()
                }
                refreshControl?.endRefreshing()
                self.handleResponse(url: url, result: result, completion: completion)
            }
        }
    }
}

// MARK: - App custom

extension UIViewController {
    var isLoggedIn: Bool {
        return Defaults.apiToken.value != nil
    }

    func logout() {
        Defaults.apiToken.value = Defaults.apiToken.defaultValue
        Defaults.userId.value = Defaults.userId.defaultValue
        Defaults.userName.value = Defaults.userName.defaultValue
        Defaults.email.value = Defaults.email.defaultValue
        Defaults.photo.value = Defaults.photo.defaultValue
        Defaults.sources.value = Defaults.sources.defaultValue
        Defaults.favorites.value = Defaults.favorites.defaultValue
    }

    func addSource() {
        let vc = CategoryVC()
        vc.page = .modifySource
        navigationController?.pushViewController(vc, animated: true)
    }

    func setupNavigationButtons() {
        let setting = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_setting_d"), style: .plain, target: self, action: #selector(onSettingNavAction))
        let search = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_search"), style: .plain, target: self, action: #selector(onSearchNavAction))
        navigationItem.leftBarButtonItem = setting
        navigationItem.rightBarButtonItem = search
    }

    @objc func onSettingNavAction() {
        navigationController?.tabBarController?.selectedIndex = 4
    }

    @objc func onSearchNavAction() {
        let vc = AppStoryboard.Main.viewController(SearchVC.self)
        navigationController?.pushViewController(vc, animated: true)
    }
}
