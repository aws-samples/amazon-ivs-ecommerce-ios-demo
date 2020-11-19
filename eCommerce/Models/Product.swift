//
//  Product.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 6/8/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import Foundation

struct Products: Decodable {
    var products: [Product] = []
}

struct Product: Decodable {
    var id: Int
    var priceDiscount: String
    var priceOriginal: String
    var imageUrl: String
    var name: String
    var webLink: String
    var isFeatured: Bool
    var lastPurchaser: Purchaser?

    init(id: Int,
         priceDiscount: String,
         priceOriginal: String,
         imageUrl: String,
         name: String,
         webLink: String,
         isFeatured: Bool,
         lastPurchaser: Purchaser?
    ) {
        self.id = id
        self.priceDiscount = priceDiscount
        self.priceOriginal = priceOriginal
        self.imageUrl = imageUrl
        self.name = name
        self.webLink = webLink
        self.isFeatured = isFeatured
        self.lastPurchaser = lastPurchaser
    }
}
