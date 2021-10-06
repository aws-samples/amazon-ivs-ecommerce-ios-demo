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
        playerView?.collapsedSize = CGRect(x: 0, y: 0, width: 100, height: 205)
        playerView?.frame = CGRect(x: 0, y: 0, width: 100, height: 205)
        playerView?.expandedSize = tableView.frame
        playerView?.collapsedCenterPosition = CGPoint(
            x: tableView.bounds.width - (playerView?.frame.width ?? 0) * 0.6,
            y: tableView.bounds.height - (playerView?.frame.height ?? 0) * 0.5
        )

        if let playerView = playerView {
            view.addSubview(playerView)
            view.bringSubviewToFront(playerView)
            playerView.setup()
            playerView.setNeedsLayout()
            view.layoutSubviews()
        }

        playerView?.state = .expanded
        playerView?.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler)))
        playerView?.products = products
    }

    @objc private func panGestureHandler(gesture: UIPanGestureRecognizer) {
        guard let playerView = playerView, playerView.state == .collapsed else {
            return
        }
        let newLocation = gesture.location(in: view)
        playerView.center = newLocation

        if gesture.state == .ended {
            let isCloserToViewTop = playerView.frame.midY <= self.view.frame.height / 2

            if playerView.frame.midX >= self.view.frame.width / 2 {
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 1,
                    initialSpringVelocity: 1,
                    options: .curveEaseIn,
                    animations: {
                        playerView.center.x = self.tableView.frame.width - playerView.frame.width * 0.6
                        playerView.center.y = isCloserToViewTop ?
                        playerView.frame.height * 0.8 :
                        self.tableView.frame.height - playerView.frame.height * 0.5
                    },
                    completion: {_ in
                        playerView.collapsedCenterPosition = playerView.center
                    }
                )
            } else {
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 1,
                    initialSpringVelocity: 1,
                    options: .curveEaseIn,
                    animations: {
                        playerView.center.x = playerView.frame.width * 0.6
                        playerView.center.y = isCloserToViewTop ?
                        playerView.frame.height * 0.8 :
                        self.tableView.frame.height - playerView.frame.height * 0.5
                    },
                    completion: {_ in
                        playerView.collapsedCenterPosition = playerView.center
                    }
                )
            }
        }
    }
}

// MARK: UITableViewDelegate

extension ProductsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 120))
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell") else {
            return UITableViewCell()
        }

        if let productView = Bundle.main.loadNibNamed("ProductView", owner: self, options: nil)?[0] as? ProductView {
            productView.setup(with: products[indexPath.row], in: cell.bounds)
            cell.addSubview(productView)
            cell.layoutSubviews()
        }

        return cell
    }
}

// MARK: PlayerViewDelegate

extension ProductsViewController: PlayerViewDelegate {
    func show(_ alert: UIAlertController, animated: Bool) {
        DispatchQueue.main.async {
            self.present(alert, animated: animated)
        }
    }
}
