//
//  ETKTools.swift
//  EMQ-iOS-Toolkit
//
//  Created by Alex Yu on 01/04/2017.
//  Copyright © 2017 EMQ. All rights reserved.
//

import UIKit

class ETKTools: NSObject {
    
    private static let base62chars = [Character]("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".characters)
    private static let maxBase : UInt32 = 62
    
    class func randomCode(withBase base: UInt32 = maxBase, length: Int) -> String {
        var code = ""
        for _ in 0..<length {
            let random = Int(arc4random_uniform(min(base, maxBase)))
            code.append(base62chars[random])
        }
        return code
    }
}

extension String {
    func isValidPublishTopic() -> Bool {
        if self.contains("+") || self.contains("#") {
            return false
        }
        
        return true
    }
}


