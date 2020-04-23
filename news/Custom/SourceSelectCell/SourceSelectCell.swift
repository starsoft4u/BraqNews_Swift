//
//  SourceSelectCell.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit

class SourceSelectCell: UITableViewCell {
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var sourceImageView: UIImageView!
    @IBOutlet weak var sourceNameLabel: UILabel!
    @IBOutlet weak var followerLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!

    var onTappedButton: (() -> Void)?

    @IBAction fileprivate func onAddButtonAction(_ sender: UIButton) {
        onTappedButton?()
    }

    func buttonState(check: Bool) {
        addButton.tag = check ? 1 : 0
        addButton.borderColor = .primaryColor
        addButton.backgroundColor = check ? .primaryColor : .white
        addButton.setImage(check ? #imageLiteral(resourceName: "ic_check"): #imageLiteral(resourceName: "ic_plus"), for: .normal)
        addButton.setTitle(check ? "" : "Add".localized, for: .normal)
        addButton.tintColor = check ? .white : .primaryColor
    }
}
