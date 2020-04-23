//
//  NSObject+ClassName.swift
//  ShopizQatar
//
//  Created by raptor on 2018/9/14.
//  Copyright © 2018 raptor. All rights reserved.
//

import Foundation

extension NSObject {
    class var dynamicClassFullName: String {
        return NSStringFromClass(self)
    }
    
    class var dynamicClassName: String {
        let p = dynamicClassFullName
        let r = p.range(of: ".")!
        return String(p[r.upperBound...])
    }
    
    var dynamicTypeFullName: String {
        return NSStringFromClass(type(of: self))
    }
    
    var dynamicTypeName: String {
        let p = dynamicTypeFullName
        let r = p.range(of: ".")!
        return String(p[r.upperBound...])
    }
}
