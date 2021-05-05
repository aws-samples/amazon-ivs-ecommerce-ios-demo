//
//  CarouselStackView.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 4/27/21.
//  Copyright © 2020 Twitch. All rights reserved.
//

import UIKit

class CountdownNumberLabel: UILabel {
    override func awakeFromNib() {
        layer.masksToBounds = true
        layer.cornerRadius = 5
    }
}

class CountdownStackView: UIStackView {
    func setupTime(from timeString: String) {
        timeString.enumerated().forEach {
            if let label = self.arrangedSubviews[$0.offset] as? UILabel {
                label.text = String($0.element)
            }
        }
    }
}
