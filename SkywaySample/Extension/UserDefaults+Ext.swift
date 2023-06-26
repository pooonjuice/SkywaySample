//
//  UserDefaults+Ext.swift
//  SkywaySample
//
//  Created by Ryo Tabuchi on 2023/06/24.
//

import Foundation

extension UserDefaults {
    private static let userNameUDKey = "userNameUDKey"
    private static let uuidUDKey = "uuidUDKey"
    
    static var userName: String? {
        get {
            UserDefaults.standard.string(forKey: userNameUDKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userNameUDKey)
        }
    }
    
    static var uuid: String {
        get {
            if let uuid = UserDefaults.standard.string(forKey: uuidUDKey) {
                return uuid
            } else {
                let uuid = UUID().uuidString
                UserDefaults.standard.set(uuid, forKey: uuidUDKey)
                return uuid
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: uuidUDKey)
        }
    }
}
