//
//  EmptyView.swift
//  news
//
//  Created by Eliot Gravett on 2019/6/21.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit

class EmptyView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var button: UIButton!

    var tappedButton: (() -> Void)?

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 200)
    }
    
    @IBAction fileprivate func onButtonAction(_ sender: UIButton) {
        tappedButton?()
    }
}
