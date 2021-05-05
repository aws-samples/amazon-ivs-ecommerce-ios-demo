//
//  CarouselItemView.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 6/2/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import UIKit

protocol CarouselItemDelegate {
    func didTapCarouselItem(avatarImage: UIImage?, itemView: UIView)
}

class CarouselItemView: UIView {

    // MARK: IBOutlet

    @IBOutlet var previewImageView: UIImageView!
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var liveLabel: UILabel!

    // MARK: Custom Actions

    func setup(previewImage: UIImage?, avatarImage: UIImage?, delegate: CarouselItemDelegate?) {
        previewImageView.image = previewImage
        avatarImageView.image = avatarImage
        self.delegate = delegate
        previewImageView.layer.cornerRadius = 10
        avatarImageView.isHidden = avatarImage == nil
        liveLabel.isHidden = avatarImageView.isHidden

        if let avatarImage = avatarImage {
            avatarImageView.image = avatarImage
            liveLabel.layer.cornerRadius = 8
        }

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
    }

    // MARK: Carousel Item Delegate

    var delegate: CarouselItemDelegate?

    @objc func onTap(_ sender: UITapGestureRecognizer) {
        delegate?.didTapCarouselItem(avatarImage: avatarImageView.image, itemView: self)
    }
}
