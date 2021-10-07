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
    private var controllsViewCollapsed: Bool = false
    private var timer: Timer?
    private var currentSeconds: Int = 11

    var delegate: PlayerViewDelegate?
    var collapsedCenterPosition = CGPoint(x: 0, y: 0)
    var collapsedSize = CGRect(x: 0, y: 0, width: 120, height: 200)
    var expandedSize = UIScreen.main.bounds
    var products: [Product] = []
    var receivedProductsLine: [Product] = []
    let jsonDecoder = JSONDecoder()

    // MARK: - IBOutlet

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
    @IBOutlet weak var bottomGradientView: UIView!
    @IBOutlet weak var timerView: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var productsPopupBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var homeButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var streamInfoPillTopConstraint: NSLayoutConstraint!

    var state: PlayerViewState? {
        didSet {
            setSizeForState()
        }
    }

    // MARK: View Lifecycle

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

    deinit {
        timer?.invalidate()
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
        timerView.layer.cornerRadius = 16
        timerView.isHidden = true
        homeButton.layer.cornerRadius = homeButton.layer.bounds.width / 2
        homeButton.titleLabel?.text = ""
        bringSubviewToFront(controlsView)

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor,
            UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        ]
        gradient.locations = [0.1, 1.0]
        gradient.frame = bottomGradientView.bounds
        bottomGradientView.layer.insertSublayer(gradient, at: 0)
    }

    // MARK: Custom actions

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
        guard state != .collapsed, currentProduct == nil else {
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
            self.timerView.isHidden = self.controllsViewCollapsed

            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.productsPopupBottomConstraint.constant = self.controllsViewCollapsed ? -30 : 50
                self.layoutIfNeeded()
            } completion: { _ in
                self.startCountdown()
            }
            currentProduct = product
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
                self.productsPopupBottomConstraint.constant = -self.productPopup.frame.height
                self.layoutIfNeeded()
            } completion: { _ in
                self.currentProduct = nil
                self.productHolderView.subviews[0].removeFromSuperview()
                self.productPopup.isHidden = true
                self.timerView.isHidden = true
                self.show(product)
            }
        }
    }

    private func startCountdown() {
        if let timer = timer {
            timer.invalidate()
        }
        currentSeconds = 11
        timerUpdated()
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(timerUpdated),
                                     userInfo: nil,
                                     repeats: true)
    }

    @objc private func timerUpdated() {
        currentSeconds -= 1
        timerLabel.text = "0:\(currentSeconds < 10 ? "0" : "")\(currentSeconds)"
        if currentSeconds == 0 {
            timerView.isHidden = true
            currentProduct = nil
            timer?.invalidate()

            if let nextProductInLine = receivedProductsLine.first {
                show(nextProductInLine)
                receivedProductsLine.remove(at: 0)
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

    // MARK: - IBAction

    @IBAction func didTapHomeButton(_ sender: Any) {
        state = .collapsed
    }

    @objc private func collapsedPlayerTapped() {
        if state == .collapsed {
            self.state = .expanded
        } else {
            controlsViewTapped()
        }
    }

    @objc private func controlsViewTapped() {
        controllsViewCollapsed.toggle()
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.streamInfoPillTopConstraint.constant = self.controllsViewCollapsed ? -100 : 8
            self.homeButtonTopConstraint.constant = self.controllsViewCollapsed ? -100 : 8
            self.productsPopupBottomConstraint.constant = self.controllsViewCollapsed ? -30 : 50
            self.timerView.isHidden = self.controllsViewCollapsed || self.currentProduct == nil
            self.bottomGradientView.isHidden = !self.controllsViewCollapsed || self.currentProduct == nil
            self.layoutIfNeeded()
        }
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
                    if receivedProductsLine.last != product {
                        receivedProductsLine.append(product)
                    }

                    if receivedProductsLine.count == 1 {
                        show(product)
                    }
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
