//
//  DetailsViewController.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 6/10/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController {

    @IBOutlet var buyNowButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        buyNowButton.layer.cornerRadius = 4
    }

    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true)
    }
}
