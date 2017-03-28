//
//  ETKConnMeta.swift
//  EMQ-iOS-Toolkit
//
//  Created by Alex Yu on 22/03/2017.
//  Copyright © 2017 EMQ. All rights reserved.
//

import UIKit

class ETKConnMeta: NSObject, NSCoding {
    open var displayName = ""
    open var host = "localhost"
    open var port = "1883"
    open var userName = ""
    open var password = ""
    
    open var updateAction: (() -> ())?
    
    required convenience init(coder aDecoder: NSCoder) {
        self.init()
        displayName = aDecoder.decodeObject(forKey: "displayName") as! String
        host = aDecoder.decodeObject(forKey: "host") as! String
        port = aDecoder.decodeObject(forKey: "port") as! String
        userName = aDecoder.decodeObject(forKey: "userName") as! String
        password = aDecoder.decodeObject(forKey: "password") as! String
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(displayName, forKey: "displayName")
        aCoder.encode(host, forKey: "host")
        aCoder.encode(port, forKey: "port")
        aCoder.encode(userName, forKey: "userName")
        aCoder.encode(password, forKey: "password")
    }
    
    open func sync() {
        if ETKConnMetaManager.sharedManager.metas.contains(self) {
            ETKConnMetaManager.sharedManager.sync()
            updateAction?()
        } else {
            print("Warning: The meta (name: \(self.displayName)) to sync is not managed by ETKConnMetaManager!")
        }
    }
}

// Singleton
final class ETKConnMetaManager: NSObject {
    
    static let sharedManager: ETKConnMetaManager = ETKConnMetaManager()
    
    //Local Variables
    var metas: [ETKConnMeta] = []
    
    // private init for singleton
    private override init() {
        if UserDefaults.standard.object(forKey: "ConnMetas") != nil {
            let decoded  = UserDefaults.standard.object(forKey: "ConnMetas") as! Data
            let decodedMetas = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [ETKConnMeta]
            metas = decodedMetas
        }
    }
    
    func createMeta() -> ETKConnMeta {
        let meta = ETKConnMeta()
        metas.append(meta)
        sync()
        return meta
    }
    
    func add(_ meta: ETKConnMeta) {
        metas.append(meta)
        sync()
    }
    
    func remove(_ meta: ETKConnMeta) {
        if !metas.contains(meta) {
            return
        }
        metas.remove(at: metas.index(of: meta)!)
        sync()
    }
    
    func remove(at indexPath: Int) {
        metas.remove(at: indexPath)
        sync()
    }
    
    func sync() {
        let userDefaults = UserDefaults.standard
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: metas)
        userDefaults.set(encodedData, forKey: "ConnMetas")
        userDefaults.synchronize()
    }
}
