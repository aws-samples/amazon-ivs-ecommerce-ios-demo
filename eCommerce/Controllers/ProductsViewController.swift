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
    private var playerView: IVSPlayerView?

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
        startPlayback()
        addApplicationLifecycleObservers()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pausePlayback()
        removeApplicationLifecycleObservers()
    }

    @objc private func applicationDidEnterBackground(notification: Notification) {
        if player?.state == .playing || player?.state == .buffering {
            pausePlayback()
        }
    }

    @objc private func applicationWillEnterForeground(notification: Notification) {
        startPlayback()
    }

    private func addApplicationLifecycleObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func removeApplicationLifecycleObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
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
        playerView = IVSPlayerView(frame: CGRect(x: 0, y: 0, width: 120, height: 200))
        guard let playerView = playerView else {
            return
        }

        playerView.backgroundColor = .black
        playerView.layer.masksToBounds = true
        playerView.center = self.view.center
        playerView.layer.cornerRadius = 10
        playerView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.addSubview(playerView)

        if let url = URL(string: Constants.portraitVideoUrlString) {
            loadStream(from: url)
            startPlayback()
        }
    }

    // MARK: - Player

    var player: IVSPlayer? {
        didSet {
            if oldValue != nil {
                removeApplicationLifecycleObservers()
            }
            playerView?.player = player
            if player != nil {
                addApplicationLifecycleObservers()
            }
        }
    }

    // MARK: Playback Control
    func loadStream(from streamURL: URL) {
        let player: IVSPlayer
        if let existingPlayer = self.player {
            player = existingPlayer
        } else {
            player = IVSPlayer()
            player.delegate = self
            self.player = player
            print("ℹ️ Player initialized: version \(player.version)")
        }
        player.load(streamURL)
    }

    private func startPlayback() {
        player?.play()
    }

    private func pausePlayback() {
        player?.pause()
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

// MARK: - IVSPlayer.Delegate
extension ProductsViewController: IVSPlayer.Delegate {

    func player(_ player: IVSPlayer, didChangeState state: IVSPlayer.State) {
//        updateForState(state)
    }

    func player(_ player: IVSPlayer, didFailWithError error: Error) {
//        presentError(error, componentName: "Player")
    }

    func player(_ player: IVSPlayer, didOutputCue cue: IVSCue) {
        switch cue {
        case let textMetadataCue as IVSTextMetadataCue:
            print("Received Timed Metadata (\(textMetadataCue.textDescription)): \(textMetadataCue.text)")
//            guard let jsonData = textMetadataCue.text.data(using: .utf8) else {
//                return
//            }
//            do {
//                self.data = try jsonDecoder.decode(Products.self, from: jsonData)
//            } catch {
//                print("Could not decode products: \(error)")
//            }
        case let textCue as IVSTextCue:
            print("Received Text Cue: “\(textCue.text)”")
        default:
            print("Received unknown cue (type \(cue.type))")
        }
    }

    func player(_ player: IVSPlayer, didOutputMetadataWithType type: String, content: Data) {
        if type == "text/plain" {
            guard let textData = String(data: content, encoding: .utf8) else {
                print("Unable to parse metadata as string")
                return
            }
            print("Received Timed Metadata: \(textData)")
        }
    }
}
