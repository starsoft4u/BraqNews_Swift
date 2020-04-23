//
//  SettingVC.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import MessageUI
import UIKit

enum SettingCellType: Int {
    case profileGuest = 0,
        profileUser,
        separator1,
        modifySource,
        newsNotification,
        soundNotification,
        separator2,
        contactUs,
        contactFacebook,
        contactTwitter,
        contactInstagram,
        contactLinkedIn,
        rate,
        share,
        suggest,
        reportBug,
        separator3,
        logout
}

class SettingVC: UITableViewController {
    @IBOutlet var avatarGuest: UIImageView!
    @IBOutlet var avatarUser: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var notifySwitch: UISwitch!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        avatarUser.sd_setImage(with: URL(string: Defaults.photo.value ?? ""), placeholderImage: #imageLiteral(resourceName: "ic_profile.png"))
        usernameLabel.text = Defaults.userName.value
        emailLabel.text = Defaults.email.value
        notifySwitch.isOn = Defaults.notifyGlobal.value

        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
    }

    func loadData() {
        get(url: "/settings") { res in
            Defaults.setting.value = Setting(json: res)
        }
    }

    func openUrl(url: String) {
        if let theUrl = URL(string: url), UIApplication.shared.canOpenURL(theUrl) {
            UIApplication.shared.open(theUrl)
        } else {
            fail("There is not associated url")
        }
    }

    @IBAction fileprivate func onNotifySwitchAction(_ sender: UISwitch) {
        Defaults.notifyGlobal.value = sender.isOn
        if sender.isOn {
            Defaults.notifications.value.forEach {
                subscribeNotification(topic: $0.description, subscribe: true)
            }
        } else {
            unsubscribeNotification()
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cellType = SettingCellType(rawValue: indexPath.row) else {
            return
        }

        switch cellType {
        case .contactUs:
            navigationController?.pushViewController(AppStoryboard.Main.viewController(ContactUsVC.self), animated: true)

        case .suggest:
            navigationController?.pushViewController(AppStoryboard.Main.viewController(SuggestionVC.self), animated: true)

        case .reportBug:
            navigationController?.pushViewController(AppStoryboard.Main.viewController(ReportBugVC.self), animated: true)

        case .modifySource:
            let vc = CategoryVC()
            vc.page = .modifySource
            navigationController?.pushViewController(vc, animated: true)

        case .soundNotification:
            openUrl(url: UIApplication.openSettingsURLString)

        case .contactFacebook:
            openUrl(url: "https://facebook.com/\(Defaults.setting.value.facebook ?? "")")

        case .contactTwitter:
            openUrl(url: "https://twitter.com/\(Defaults.setting.value.twitter ?? "")")

        case .contactInstagram:
            openUrl(url: "https://instagram.com/\(Defaults.setting.value.instagram ?? "")")

        case .contactLinkedIn:
            openUrl(url: "https://linkedin.com/\(Defaults.setting.value.linkedIn ?? "")")

        case .share:
            let vc = UIActivityViewController(activityItems: ["Share Content".localized], applicationActivities: nil)
            present(vc, animated: true, completion: nil)

        case .logout:
            logout()
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)

        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if Defaults.userId.value == 0 {
            if indexPath.row == SettingCellType.profileUser.rawValue ||
                indexPath.row == SettingCellType.separator3.rawValue ||
                indexPath.row == SettingCellType.logout.rawValue {
                return 0
            }
        } else if indexPath.row == SettingCellType.profileGuest.rawValue {
            return 0
        }

        return UITableView.automaticDimension
    }

    @IBAction func unwind2Setting(_ sender: UIStoryboardSegue) {
        tableView.reloadData()
    }
}
