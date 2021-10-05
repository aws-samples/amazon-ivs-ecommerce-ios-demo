//
//  Image.swift
//  eCommerce
//
//  Created by Uldis Zingis on 05/10/2021.
//  Copyright © 2021 Twitch. All rights reserved.

import UIKit

struct Image {
    static func getFrom(_ url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url, completionHandler: { (data, _, error) in
            guard let data = data, error == nil else {
                print("❌ Error getting image from \(url.absoluteString): \(error!)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            if let image = UIImage(data: data) {
                DispatchQueue.main.async { completion(image) }
            } else {
                print("❌ Could not get UIImage from data \(data)")
                DispatchQueue.main.async { completion(nil) }
            }
        }).resume()
    }
}
