//
//  ProductViewCell.swift
//  eCommerce
//
//  Created by Uldis Zingis on 01/10/2021.
//  Copyright © 2021 Twitch. All rights reserved.

import UIKit

class ProductViewCell: UITableViewCell {

    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var discountLabel: UILabel!

    func setup(with product: Product) {
        if var imageUrl = URL(string: Constants.productImageBaseUrl) {
            imageUrl.appendPathComponent(product.imageUrl)
            getImageFrom(imageUrl) { [weak self] (image) in
                DispatchQueue.main.async {
                    self?.productImageView.image = image
                }
            }
        }

        productImageView.layer.cornerRadius = 10
        titleLabel.text = product.name
        if product.discountedPrice != 0 {
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: "$\(product.price)")
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0, attributeString.length))
            priceLabel.attributedText = attributeString
        } else {
            priceLabel.text = "$\(product.price)"
        }

        discountLabel.text = "$\(product.discountedPrice)"
        discountLabel.isHidden = product.discountedPrice == 0
    }

    private func getImageFrom(_ url: URL, completion: @escaping (UIImage?) -> Void) {
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
