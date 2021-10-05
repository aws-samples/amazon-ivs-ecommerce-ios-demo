//
//  ProductView.swift
//  eCommerce
//
//  Created by Uldis Zingis on 05/10/2021.
//  Copyright © 2021 Twitch. All rights reserved.

import UIKit

class ProductView: UIView {
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var discountLabel: UILabel!

    func setup(with product: Product, in frame: CGRect) {
        self.frame = frame

        if var imageUrl = URL(string: Constants.productImageBaseUrl) {
            imageUrl.appendPathComponent(product.imageUrl)
            Image.getFrom(imageUrl) { [weak self] (image) in
                DispatchQueue.main.async {
                    self?.productImageView.image = image
                }
            }
        }

        productImageView.layer.cornerRadius = 10
        titleLabel.text = product.name
        if product.discountedPrice != product.price {
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: "$\(product.price)")
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0, attributeString.length))
            priceLabel.attributedText = attributeString
        } else {
            priceLabel.text = "$\(product.price)"
            priceLabel.textColor = .white
        }

        discountLabel.text = "$\(product.discountedPrice)"
        discountLabel.isHidden = product.discountedPrice == product.price

        setNeedsLayout()
        layoutIfNeeded()
    }
}
