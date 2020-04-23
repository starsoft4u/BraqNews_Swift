//
//  NewsHeaderView.swift
//  news
//
//  Created by Eliot Gravett on 2019/6/21.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit

class NewsHeaderView: UIView {
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var sourceImageView: UIImageView!
    @IBOutlet var sourceNameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var followersLabel: UILabel!
    @IBOutlet var followButton: UIButton!
    @IBOutlet var notifySwitch: UISwitch!

    var tappedButton: (() -> Void)?
    var tappedSwitch: ((Bool) -> Void)?

    @IBAction fileprivate func onButtonAction(_ sender: UIButton) {
        tappedButton?()
    }

    @IBAction fileprivate func onSwitchAction(_ sender: UISwitch) {
        tappedSwitch?(sender.isOn)
    }

    func buttonState(check: Bool) {
        followButton.borderColor = .primaryColor
        followButton.backgroundColor = check ? .primaryColor : .white
        followButton.tintColor = check ? .white : .primaryColor
    }
}
