//
//  Helpers.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 6/16/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import UIKit

extension UIViewController {
    func getPagedContentOffsetX(_ scrollView: UIScrollView, velocity: CGPoint, itemWidth: CGFloat, maxIndex: CGFloat) -> CGFloat {
        let targetX = scrollView.contentOffset.x + velocity.x * 20
        var targetIndex: CGFloat = 0

        if (velocity.x > 0) {
            targetIndex = ceil(targetX / itemWidth)
        } else if (velocity.x == 0) {
            targetIndex = round(targetX / itemWidth)
        } else if (velocity.x < 0) {
            targetIndex = floor(targetX / itemWidth)
        }
        targetIndex = targetIndex < 0 ? 0 : targetIndex
        targetIndex = targetIndex > maxIndex ? maxIndex : targetIndex
        return targetIndex * itemWidth
    }
}
