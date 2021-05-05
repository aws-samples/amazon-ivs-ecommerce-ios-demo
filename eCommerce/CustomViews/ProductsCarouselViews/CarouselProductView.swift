//
//  CarouselProductView.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 6/8/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import UIKit

protocol CarouselProductItemDelegate {
    func didTapLearnMore()
    func didTapBuyNow(_ product: Product?)
    func featuredItemChanged(to newPosition: CGRect)
}

class CarouselProductView: UIView {

    // MARK: IBOutlet

    @IBOutlet var contentView: UIView!
    @IBOutlet var productImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var oldPriceLabel: UILabel!
    @IBOutlet var oldPriceWidth: NSLayoutConstraint!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var onStreamView: UIImageView!
    @IBOutlet var learnMoreButton: UIButton!
    @IBOutlet var buyButton: UIButton!
    @IBOutlet var purchaserImageView: UIImageView!
    @IBOutlet var purchaserLabel: UILabel!

    // MARK: @IBAction

    @IBAction func learnMoreTapped(_ sender: Any) {
        delegate?.didTapLearnMore()
    }

    @IBAction func buyTapped(_ sender: Any) {
        delegate?.didTapBuyNow(product)
    }

    // MARK: Carousel Item Delegate

    var delegate: CarouselProductItemDelegate?

    // MARK: Custom Actions

    let imagesBaseUrlString = "https://d39ii5l128t5ul.cloudfront.net/assets/ecommerce"
    var product: Product?

    func setup(_ product: Product, _ delegate: CarouselProductItemDelegate?) {
        self.delegate = delegate

        contentView.layer.cornerRadius = 10
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.45
        contentView.layer.shadowOffset = CGSize(width: 5, height: 10)
        contentView.layer.shadowRadius = 10

        productImageView.layer.cornerRadius = 5
        productImageView.layer.borderWidth = 1
        productImageView.layer.borderColor = UIColor.lightGray.cgColor

        learnMoreButton.layer.cornerRadius = 4
        buyButton.layer.cornerRadius = 4
        purchaserImageView.layer.cornerRadius = 8

        update(with: product)
    }

    func update(with product: Product) {
        self.product = product

        if let productImageUrl = URL(string: imagesBaseUrlString + product.imageUrl) {
            getImageFrom(productImageUrl) { [weak self] (image) in
                self?.productImageView.image = image
            }
        }

        if product.priceDiscount == "" {
            oldPriceWidth.constant = 0
            priceLabel.text = product.priceOriginal
        } else {
            let strikedThroughOldPrice: NSMutableAttributedString =  NSMutableAttributedString(string: product.priceOriginal)
            strikedThroughOldPrice.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 1, range: NSMakeRange(0, strikedThroughOldPrice.length))
            oldPriceLabel.attributedText = strikedThroughOldPrice
            priceLabel.text = product.priceDiscount
        }

        nameLabel.text = product.name
        UIView.animate(withDuration: 0.5) {
            if product.isFeatured {
                self.onStreamView.alpha = 1
                if let newPosition = self.superview?.convert(self.frame.origin, to: self.superview) {
                    self.delegate?.featuredItemChanged(to: CGRect(x: newPosition.x, y: newPosition.y, width: 320, height: 200))
                }
            } else {
                self.onStreamView.alpha = 0
            }
        }

        if let purchaser = product.lastPurchaser {
            if let purchaserImageUrl = URL(string: imagesBaseUrlString + purchaser.userprofile) {
                getImageFrom(purchaserImageUrl) { [weak self] (image) in
                    self?.purchaserImageView.image = image
                }
            }
            purchaserLabel.text = "\(purchaser.username) purchased now"
        } else {
            purchaserLabel.isHidden = true
            purchaserImageView.isHidden = true
        }
    }

    private func getImageFrom(_ url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard let data = data, error == nil else {
                print("Error getting image from \(url.absoluteString): \(error!)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            if let image = UIImage(data: data) {
                DispatchQueue.main.async { completion(image) }
            } else {
                print("Could not get UIImage from data \(data)")
                DispatchQueue.main.async { completion(nil) }
            }
        }).resume()
    }
}
