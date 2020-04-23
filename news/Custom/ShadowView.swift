//
//  ShadowView.swift
//  news
//
//  Created by Eliot Gravett on 2019/5/23.
//  Copyright © 2019 Barq. All rights reserved.
//

import UIKit

class ShadowView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        layer.shadowOffset = CGSize(width: 0.3, height: 0.3)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 1
    }

}
