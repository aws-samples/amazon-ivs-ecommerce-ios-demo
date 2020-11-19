//
//  CarouselStackView.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 6/2/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import UIKit

class CarouselStackView: UIStackView {

    // MARK: Custom Actions

    func removeAllArrangedSubviews() {
        for view in subviews {
            view.removeFromSuperview()
        }
    }

    func addStreamItem(previewImageName: String, avatarImageName: String, delegate: CarouselItemDelegate?){
        if let nibView = Bundle.main.loadNibNamed("CarouselItem", owner: self, options: nil)?.first as? CarouselItemView {
            addArrangedSubview(nibView)
            nibView.setup(previewImage: UIImage(named: previewImageName), avatarImage: UIImage(named: avatarImageName), delegate: delegate)
        }
    }

    func addProductItem(_ product: Product, delegate: CarouselProductItemDelegate?){
        for subview in subviews {
            if let productView = subview as? CarouselProductView, productView.product?.id == product.id {
                productView.update(with: product)
                return
            }
        }

        if let nibView = Bundle.main.loadNibNamed("CarouselProduct", owner: self, options: nil)?.first as? CarouselProductView {
            addArrangedSubview(nibView)
            nibView.setup(product, delegate)
        }
    }
}
