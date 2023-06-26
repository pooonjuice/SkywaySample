//
//  Room.swift
//  SkywaySample
//
//  Created by Ryo Tabuchi on 2023/06/24.
//

import Foundation
import SwiftyJSON

struct SSRoom {
    let id: String
    let name: String
    let password: String?
}

extension SSRoom {
    init?(json: JSON) {
        guard let id = json["id"].string,
            let name = json["name"].string else {
            return nil
        }
        self.init(id: id,
                  name: name,
                  password: json["password"].string)
    }
}
