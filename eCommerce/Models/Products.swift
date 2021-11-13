//
//  Product.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 6/8/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import UIKit

struct Products: Decodable {
    var items: [Product] = []

    enum CodingKeys: String, CodingKey {
        case items = "products"
    }
}

struct Product: Decodable, Equatable {
    var id: String
    var name: String
    var imageUrl: String
    var imageLargeUrl: String
    var price: Int
    var discountedPrice: Int
    var longDescription: String

    func getImage(completion: @escaping (UIImage?) -> Void) {
        if var url = URL(string: Constants.productImageBaseUrl) {
            url.appendPathComponent(imageUrl)
            Image.getFrom(url) { image in
                completion(image)
            }
        }
    }
}
