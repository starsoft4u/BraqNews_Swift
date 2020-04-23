//
//  UIView+Borders.swift
//
//  Created by Aaron Ng on 11/15/15.
//  Copyright © 2015 Aaron Ng. All rights reserved.
//

import UIKit

public extension UIView {
    class var nibName: String {
        return self.dynamicClassName
    }

    class var identifier: String {
        return self.nibName
    }

    static func loadFromNib<T: UIView>() -> T {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: self.nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: nil, options: nil).first as! T
        return view
    }

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            } else {
                return nil
            }
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}
