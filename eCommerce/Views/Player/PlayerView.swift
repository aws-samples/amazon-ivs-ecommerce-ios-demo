//
//  PlayerView.swift
//  eCommerce
//
//  Created by Uldis Zingis on 04/10/2021.
//  Copyright © 2021 Twitch. All rights reserved.

import UIKit
import AmazonIVSPlayer

enum PlayerViewState {
    case collapsed, expanded
}

protocol PlayerViewDelegate {
    func show(_ alert: UIAlertController, animated: Bool)
}

class PlayerView: UIView {
    private var ivsView: IVSPlayerView?
    private var currentProduct: Product?

    var delegate: PlayerViewDelegate?
    var collapsedCenterPosition = CGPoint(x: 0, y: 0)
    var collapsedSize = CGRect(x: 0, y: 0, width: 120, height: 200)
    var expandedSize = UIScreen.main.bounds
    var products: [Product] = []
    let jsonDecoder = JSONDecoder()

    @IBOutlet weak var controlsView: UIView! {
        didSet {
            controlsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(controlsViewTapped)))
        }
    }
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var bufferIndicator: UIActivityIndicatorView!
    @IBOutlet weak var streamInfoPill: UIView!
    @IBOutlet weak var streamInfoPillImageView: UIImageView!
    @IBOutlet weak var productPopup: UIView!
    @IBOutlet weak var productAddToCartButton: UIButton!
    @IBOutlet weak var productBuyNowButton: UIButton!
    @IBOutlet weak var productHolderView: UIView!
    @IBOutlet weak var productsPopupBottomConstraint: NSLayoutConstraint!

    var state: PlayerViewState? {
        didSet {
            setSizeForState()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        ivsView = IVSPlayerView(frame: expandedSize)
        guard let ivsView = ivsView else {
            return
        }
        ivsView.backgroundColor = .black
        ivsView.layer.masksToBounds = true
        ivsView.clipsToBounds = true
        ivsView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        ivsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(collapsedPlayerTapped)))
        self.addSubview(ivsView)

        if let url = URL(string: Constants.streamUrl) {
            loadStream(from: url)
            startPlayback()
        }
    }

    func addApplicationLifecycleObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    func removeApplicationLifecycleObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func applicationDidEnterBackground(notification: Notification) {
        if player?.state == .playing || player?.state == .buffering {
            pausePlayback()
        }
    }

    @objc private func applicationWillEnterForeground(notification: Notification) {
        startPlayback()
    }

    func setup() {
        streamInfoPill.backgroundColor = .white
        streamInfoPill.layer.cornerRadius = 25
        streamInfoPillImageView.layer.cornerRadius = streamInfoPillImageView.frame.size.width / 2
        if let imageUrl = URL(string: "https://ecommerce.ivsdemos.com/images/profile.png") {
            Image.getFrom(imageUrl) { [weak self] (image) in
                DispatchQueue.main.async {
                    self?.streamInfoPillImageView.image = image
                }
            }
        }
        productAddToCartButton.layer.cornerRadius = 4
        productBuyNowButton.layer.cornerRadius = 4
        productPopup.layer.cornerRadius = 16
        homeButton.layer.cornerRadius = homeButton.layer.bounds.width / 2
        homeButton.titleLabel?.text = ""
        bringSubviewToFront(controlsView)
    }

    private func setSizeForState() {
        switch state {
        case .collapsed:
            self.frame = collapsedSize
            self.layer.cornerRadius = 10
            ivsView?.frame = self.bounds
            ivsView?.layer.cornerRadius = 10
            self.center = collapsedCenterPosition
            controlsView.isHidden = true

        case .expanded:
            self.frame = expandedSize
            self.layer.cornerRadius = 30
            ivsView?.frame = self.bounds
            ivsView?.layer.cornerRadius = 30
            showControlsView()

        case .none:
            break
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    private func showControlsView() {
        controlsView.isHidden = false
    }

    private func show(_ product: Product) {
        guard currentProduct == nil else {
            return
        }

        self.layoutIfNeeded()
        if productPopup.isHidden {
            if let productView = Bundle.main.loadNibNamed("ProductView", owner: self, options: nil)?[0] as? ProductView {
                productView.setup(with: product, in: productHolderView.bounds)
                productHolderView.addSubview(productView)
                productHolderView.layoutSubviews()
            }
            self.productPopup.isHidden = false

            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.productsPopupBottomConstraint.constant = 50
                self.layoutIfNeeded()
            }
            currentProduct = product
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.productsPopupBottomConstraint.constant = -self.productPopup.frame.height
                self.layoutIfNeeded()
            } completion: { _ in
                self.currentProduct = nil
                self.productHolderView.subviews[0].removeFromSuperview()
                self.productPopup.isHidden = true
                self.show(product)
            }
        }
    }

    // MARK: - Player

    var player: IVSPlayer? {
        didSet {
            if oldValue != nil {
                removeApplicationLifecycleObservers()
            }
            ivsView?.player = player
            if player != nil {
                addApplicationLifecycleObservers()
            }
        }
    }

    // MARK: Playback Control
    private func loadStream(from streamURL: URL) {
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

    func startPlayback() {
        player?.play()
    }

    func pausePlayback() {
        player?.pause()
    }

    @objc private func controlsViewTapped() {
        // TODO: - toggle topBar

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.productsPopupBottomConstraint.constant = self.productsPopupBottomConstraint.constant < 0 ? 50 : -60
            self.layoutIfNeeded()
        }
    }

    @objc private func collapsedPlayerTapped() {
        if state == .collapsed {
            self.state = .expanded
        } else {
            controlsViewTapped()
        }
    }

    @IBAction func didTapHomeButton(_ sender: Any) {
        state = .collapsed
    }

    // MARK: State display

    private func presentError(_ error: Error, componentName: String) {
        let alert = UIAlertController(title: "\(componentName) Error", message: String(reflecting: error), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        delegate?.show(alert, animated: true)
    }

    private func presentAlert(_ message: String, componentName: String) {
        let alert = UIAlertController(title: "\(componentName)", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        delegate?.show(alert, animated: true)
    }

    private func updateForState(_ state: IVSPlayer.State) {
        if state == .buffering {
            bufferIndicator?.startAnimating()
        } else {
            bufferIndicator?.stopAnimating()
        }
    }
}

// MARK: - IVSPlayer.Delegate

extension PlayerView: IVSPlayer.Delegate {
    func player(_ player: IVSPlayer, didChangeState state: IVSPlayer.State) {
        updateForState(state)
    }

    func player(_ player: IVSPlayer, didFailWithError error: Error) {
        presentError(error, componentName: "Player")
    }

    func player(_ player: IVSPlayer, didOutputCue cue: IVSCue) {
        switch cue {
        case let textMetadataCue as IVSTextMetadataCue:
            print("ℹ Received Timed Metadata (\(textMetadataCue.textDescription)): \(textMetadataCue.text)")
            guard let jsonData = textMetadataCue.text.data(using: .utf8) else {
                return
            }
            do {
                let json = try jsonDecoder.decode([String: String].self, from: jsonData)
                if let id = json["productId"], let product = products.first(where: { $0.id == id }) {
                    show(product)
                }
            } catch {
                print("Could not decode productId: \(error)")
            }
        case let textCue as IVSTextCue:
            print("ℹ Received Text Cue: “\(textCue.text)”")
        default:
            print("ℹ Received unknown cue (type \(cue.type))")
        }
    }
}
