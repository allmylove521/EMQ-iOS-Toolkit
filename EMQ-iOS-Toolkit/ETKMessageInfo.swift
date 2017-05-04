//
//  ETKMessage.swift
//  EMQ-iOS-Toolkit
//
//  Created by Alex Yu on 02/05/2017.
//  Copyright © 2017 EMQ. All rights reserved.
//

import UIKit
import CocoaMQTT

enum ETKMessageInfoType {
    case publish
    case receive
}

class ETKMessageInfo: NSObject {
    
    var message: CocoaMQTTMessage?
    var date: Date?
    var type: ETKMessageInfoType?
    var sent: Bool = false // only use for publishing message
    var msgid: UInt16?
    
    var topic: String {
        return (message?.topic)!
    }
    
    var string: String {
        return (message?.string!)!
    }
    
    var qos: CocoaMQTTQOS {
        return message!.qos
    }

    init(message: CocoaMQTTMessage, date: Date, type: ETKMessageInfoType) {
        self.message = message
        self.date = date
        self.type = type
    }
}
