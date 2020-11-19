//
//  WatchViewController.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 6/4/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import UIKit
import AmazonIVSPlayer
import PassKit

class WatchViewController: UIViewController {

    // MARK: IBOutlet

    @IBOutlet var backgroundViewImage: UIImageView!
    @IBOutlet var playerView: IVSPlayerView!
    @IBOutlet var bufferIndicator: UIActivityIndicatorView!
    @IBOutlet var streamInfoView: UIView!
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var productsScrollView: UIScrollView!
    @IBOutlet var productsStackView: UIStackView!
    @IBOutlet var productsCarouselStackView: CarouselStackView!
    @IBOutlet var productsScrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var topGradientView: UIView!
    @IBOutlet var bottomGradientView: UIView!
    @IBOutlet var bottomCardsOverlayGradient: UIView!

    // MARK: IBAction

    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if let streamUrlString = streamUrlString, let url = URL(string: streamUrlString) {
            loadStream(from: url)
            startPlayback()
        }
        setupInfoView()
        data = nil
        cleanupCarousel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupGradients()
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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: Application Lifecycle

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

    // MARK: State display

    private func presentError(_ error: Error, componentName: String) {
        let alert = UIAlertController(title: "\(componentName) Error", message: String(reflecting: error), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(alert, animated: true)
    }

    private func presentAlert(_ message: String, componentName: String) {
        let alert = UIAlertController(title: "\(componentName)", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(alert, animated: true)
    }

    private func updateForState(_ state: IVSPlayer.State) {
        if state == .buffering {
            bufferIndicator?.startAnimating()
        } else {
            bufferIndicator?.stopAnimating()
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

    // MARK: Overlay

    let jsonDecoder = JSONDecoder()
    var avatarImage: UIImage?
    var streamUrlString: String?
    var data: Products? {
        didSet {
            if let data = data, productsCarouselStackView.subviews.count == 0 {
                toggleCarousel(data.products.count > 0)
            }
            for product in data?.products ?? [] {
                productsCarouselStackView.addProductItem(product, delegate: self)
            }
        }
    }
    var isOverlayHidden: Bool = false
    var featuredViewPosition: CGRect?

    private func setupInfoView() {
        addTapGesture(to: backgroundViewImage)
        addTapGesture(to: topGradientView)
        addTapGesture(to: bottomGradientView)
        addTapGesture(to: bottomCardsOverlayGradient)

        addSwipeGesture(to: backgroundViewImage)
        addSwipeGesture(to: topGradientView)
        addSwipeGesture(to: bottomGradientView)

        backgroundViewImage.layer.cornerRadius = 20
        playerView.layer.cornerRadius = 20
        view.layer.cornerRadius = 20
        avatarImageView.image = avatarImage

        productsScrollView.delegate = self
    }

    private func addTapGesture(to view: UIView) {
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleOverlay)))
    }

    private func addSwipeGesture(to view: UIView) {
        let swipeGestureDown = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeDown))
        swipeGestureDown.direction = UISwipeGestureRecognizer.Direction.down
        view.addGestureRecognizer(swipeGestureDown)
    }

    private func setupGradients() {
        addGradient(
            to: topGradientView,
            startColor: UIColor(red: 40 / 255, green: 42 / 255, blue: 60 / 255, alpha: 0.56),
            endColor: UIColor(red: 40 / 255, green: 42 / 255, blue: 60 / 255, alpha: 0)
        )
        topGradientView.layer.cornerRadius = 20
        addGradient(
            to: bottomGradientView,
            startColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0),
            endColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.83)
        )
        addGradient(
            to: bottomCardsOverlayGradient,
            startColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0),
            endColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        )
    }

    private func addGradient(to view: UIView, startColor: UIColor, endColor: UIColor) {
        if view.layer.sublayers == nil {
            let gradient = CAGradientLayer()
            gradient.colors = [startColor.cgColor, endColor.cgColor]
            gradient.frame = view.bounds
            gradient.cornerRadius = 15
            view.layer.insertSublayer(gradient, at: 0)
        }
    }

    @objc private func toggleOverlay() {
        productsScrollViewBottomConstraint.constant = isOverlayHidden ? 50 : -120
        UIView.animate(withDuration: 0.3) {
            self.streamInfoView.alpha = self.isOverlayHidden ? 1 : 0
            self.topGradientView.alpha = self.isOverlayHidden ? 1 : 0.1
            self.bottomGradientView.alpha = self.isOverlayHidden ? 1 : 0.1
            self.bottomCardsOverlayGradient.alpha = self.isOverlayHidden ? 0 : 1
            self.view.layoutIfNeeded()
        }
        isOverlayHidden = !isOverlayHidden
    }

    @objc private func didSwipeDown() {
        dismiss(animated: true)
    }

    private func cleanupCarousel() {
        productsCarouselStackView.removeAllArrangedSubviews()
    }

    private func toggleCarousel(_ show: Bool) {
        productsScrollViewBottomConstraint.constant = -120
        view.layoutIfNeeded()
        productsScrollView.alpha = 0
        productsScrollViewBottomConstraint.constant = 50
        UIView.animate(withDuration: 0.5) {
            self.productsScrollView.alpha = show ? 1 : 0
            self.bottomGradientView.alpha = show ? 1 : 0
            self.bottomCardsOverlayGradient.alpha = show ? 0 : 1
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - IVSPlayer.Delegate

extension WatchViewController: IVSPlayer.Delegate {

    func player(_ player: IVSPlayer, didChangeState state: IVSPlayer.State) {
        updateForState(state)
    }

    func player(_ player: IVSPlayer, didFailWithError error: Error) {
        presentError(error, componentName: "Player")
    }

    func player(_ player: IVSPlayer, didOutputCue cue: IVSCue) {
        switch cue {
        case let textMetadataCue as IVSTextMetadataCue:
            print("Received Timed Metadata (\(textMetadataCue.textDescription)): \(textMetadataCue.text)")
            guard let jsonData = textMetadataCue.text.data(using: .utf8) else {
                return
            }
            do {
                self.data = try jsonDecoder.decode(Products.self, from: jsonData)
            } catch {
                print("Could not decode products: \(error)")
            }
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

    func player(_ player: IVSPlayer, didChangeQuality quality: IVSQuality?) {
        playerView.videoGravity = player.videoSize.height > player.videoSize.width ? AVLayerVideoGravity.resizeAspectFill : AVLayerVideoGravity.resizeAspect
    }
}

// MARK: CarouselItemDelegate

extension WatchViewController: CarouselProductItemDelegate {
    func didTapLearnMore() {
        performSegue(withIdentifier: "showDetailsView", sender: self)
    }

    func didTapBuyNow(_ product: Product?) {
        guard let product = product else { return }
        let paymentNetworks = [PKPaymentNetwork.amex, .discover, .masterCard, .visa]
        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {
            let request = PKPaymentRequest()
            request.currencyCode = "USD"
            request.countryCode = "US"
            request.merchantIdentifier = ""
            request.merchantCapabilities = PKMerchantCapability.capability3DS
            request.supportedNetworks = paymentNetworks

            let formatter = NumberFormatter()
            formatter.generatesDecimalNumbers = true
            let productPriceString = product.priceDiscount != "" ? product.priceDiscount : product.priceOriginal
            let productPrice = productPriceString.components(separatedBy:CharacterSet.decimalDigits.inverted).joined()
            let price = formatter.number(from: productPrice) as? NSDecimalNumber ?? 0
            request.paymentSummaryItems = [PKPaymentSummaryItem.init(label: product.name, amount: price)]

            guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                presentAlert("Unable to present Apple Pay authorization", componentName: "Apple Pay Error")
                return
            }
            paymentVC.delegate = self
            self.present(paymentVC, animated: true, completion: nil)
        } else {
            presentAlert("Unable to make Apple Pay transaction", componentName: "Apple Pay Error")
        }
    }

    func featuredItemChanged(to newPosition: CGRect) {
        if featuredViewPosition != newPosition {
            productsScrollView.scrollRectToVisible(newPosition, animated: true)
            featuredViewPosition = newPosition
        }
    }
}

// MARK: PKPaymentAuthorizationViewControllerDelegate

extension WatchViewController: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        dismiss(animated: true, completion: nil)
    }

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        dismiss(animated: true, completion: nil)
        presentAlert("The Apple Pay transaction was succcessful", componentName: "Apple Pay")
    }
}

// MARK: UIScrollViewDelegate

extension WatchViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        targetContentOffset.pointee.x = getPagedContentOffsetX(scrollView, velocity: velocity, itemWidth: 320, maxIndex: CGFloat(productsStackView.subviews.count))
    }
}
