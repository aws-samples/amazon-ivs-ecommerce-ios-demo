//
//  ViewController.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 5/29/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import UIKit
import AmazonIVSPlayer

class ProductsViewController: UIViewController {

    // MARK: IBOutlet
    @IBOutlet weak var tableView: UITableView!
    private var playerView: PlayerView?

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.layer.cornerRadius = 30

        loadProducts()

        createPlayerView()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView?.startPlayback()
        playerView?.addApplicationLifecycleObservers()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playerView?.pausePlayback()
        playerView?.removeApplicationLifecycleObservers()
    }

    // MARK: Custom actions

    private var products: [Product] = []

    private func loadProducts() {
        if let path = Bundle.main.path(forResource: "Products", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                do {
                    self.products = try JSONDecoder().decode(Products.self, from: data).items
                } catch {
                    print("‼️ Error decoding products: \(error)")
                }
            } catch {
                print("‼️ Error: \(error)")
            }
        }
    }

    private func createPlayerView() {
        playerView = Bundle.main.loadNibNamed("PlayerView", owner: self, options: nil)?[0] as? PlayerView
        playerView?.collapsedSize = CGRect(x: 0, y: 0, width: 120, height: 200)
        playerView?.frame = CGRect(x: 0, y: 0, width: 120, height: 200)
        playerView?.expandedSize = tableView.frame
        playerView?.collapsedCenterPosition = CGPoint(
            x: tableView.bounds.width - (playerView?.frame.width ?? 0) * 0.6,
            y: tableView.bounds.height - (playerView?.frame.height ?? 0) * 0.5
        )

        if let playerView = playerView {
            view.addSubview(playerView)
            view.bringSubviewToFront(playerView)
            playerView.setNeedsLayout()
            view.layoutSubviews()
        }

        playerView?.state = .expanded
    }
}

// MARK: UITableViewDelegate

extension ProductsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 60))
        let title = UILabel()
        title.frame = CGRect.init(x: 16, y: 0, width: headerView.frame.width, height: headerView.frame.height)
        title.textColor = .white
        title.font = UIFont(name: "AmazonEmber-Bold", size: 24)
        title.text = "All Products"
        headerView.addSubview(title)
        return headerView
    }
}

// MARK: UITableViewDataSource

extension ProductsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell") as? ProductViewCell else {
            return UITableViewCell()
        }
        cell.setup(with: products[indexPath.row])
        return cell
    }
}
