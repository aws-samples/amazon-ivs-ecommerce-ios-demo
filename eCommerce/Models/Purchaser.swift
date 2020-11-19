//
//  Purchaser.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 6/8/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import Foundation

struct Purchaser: Decodable {
    var username: String
    var userprofile: String

    init(username: String, userprofile: String) {
        self.username = username
        self.userprofile = userprofile
    }
}
