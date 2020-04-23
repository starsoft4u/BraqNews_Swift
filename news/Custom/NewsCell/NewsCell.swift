//
//  NewsCell.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit

class NewsCell: UITableViewCell {
    @IBOutlet weak var sourceIcon: UIImageView!
    @IBOutlet weak var sourceNameLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var bottomView: UIStackView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    var tappedComment: (() -> Void)?
    var tappedShare: (()->Void)?

    @IBAction fileprivate func onShareAction(_ sender: Any) {
        tappedShare?()
    }

    @IBAction fileprivate func onCommentAction(_ sender: Any) {
        tappedComment?()
    }
}
