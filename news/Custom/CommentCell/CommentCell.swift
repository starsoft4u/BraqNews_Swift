//
//  CommentCell.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/24.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dislikeLabel: UILabel!
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var flagLabel: UILabel!
    @IBOutlet weak var flagButton: UIButton!

    var tappedLike: (() -> Void)?
    var tappedDislike: (() -> Void)?
    var tappedFlagged: (() -> Void)?

    var liked: Bool = false {
        didSet {
            likeButton.setImage(liked ? #imageLiteral(resourceName: "ic_like_d"): #imageLiteral(resourceName: "ic_like"), for: .normal)
        }
    }
    var disliked: Bool = false {
        didSet {
            dislikeButton.setImage(disliked ? #imageLiteral(resourceName: "ic_dislike_d"): #imageLiteral(resourceName: "ic_dislike"), for: .normal)
        }
    }
    var flagged: Bool = false {
        didSet {
            flagButton.tintColor = flagged ? .accentColor : .lightGray
        }
    }

    @IBAction fileprivate func onLikeAction(_ sender: UIButton) {
        tappedLike?()
    }

    @IBAction fileprivate func onDislikeAction(_ sender: UIButton) {
        tappedDislike?()
    }

    @IBAction fileprivate func onFlagAction(_ sender: UIButton) {
        tappedFlagged?()
    }
}
