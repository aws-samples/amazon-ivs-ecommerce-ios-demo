//
//  ViewController.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 5/29/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import UIKit

struct CarouselItem {
    var previewImage: UIImage
    var avatarImage: UIImage
}

class HomeViewController: UIViewController {

    // MARK: Stream urls

    private let portraitVideoUrlString = "https://4da4a22026d3.us-west-2.playback.live-video.net/api/video/v1/us-west-2.298083573632.channel.WbhDQYgfYHoT.m3u8"
    private let landscapeVideoUrlString = "https://4da4a22026d3.us-west-2.playback.live-video.net/api/video/v1/us-west-2.298083573632.channel.JQj8mTBfhb7e.m3u8"
    private var tappedStreamUrl = ""

    // MARK: IBOutlet

    @IBOutlet var countDownLabel: UILabel!
    @IBOutlet var streamsCarouselStackView: CarouselStackView!
    @IBOutlet var streamsScrollView: UIScrollView!

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTimer()
        setupCarousel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(setTimeUntilMidnight), userInfo: nil, repeats: true)
        RunLoop.current.add(countdownTimer!, forMode: .common)

        view.backgroundColor = .white
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        countdownTimer?.invalidate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    // MARK: Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLiveStream", let watchView = segue.destination as? WatchViewController {
            watchView.avatarImage = tappedAvatarImage
            watchView.streamUrlString = tappedStreamUrl
        }
    }

    // MARK: Custom actions

    private let calendar = Calendar.current
    private let formatter = DateComponentsFormatter()
    private var components: DateComponents?
    private var countdownTimer: Timer?
    private var tappedAvatarImage: UIImage?

    func setupTimer() {
        components = DateComponents(calendar: calendar, hour: 0)
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        setTimeUntilMidnight()
    }

    @objc private func setTimeUntilMidnight() {
        let now = Date()
        guard let components = components, let next = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) else { return }
        let diff = calendar.dateComponents([.hour, .minute, .second], from: now, to: next)

        DispatchQueue.main.async {
            self.countDownLabel.text = self.formatter.string(from: diff)
        }
    }

    func setupCarousel() {
        streamsScrollView.delegate = self
        streamsCarouselStackView.removeAllArrangedSubviews()
        streamsCarouselStackView.addStreamItem(previewImageName: "live_carousel_image_1",
                                               avatarImageName: "avatar_1", delegate: self)
        streamsCarouselStackView.addStreamItem(previewImageName: "live_carousel_image_2",
                                               avatarImageName: "avatar_2", delegate: self)
        streamsCarouselStackView.addStreamItem(previewImageName: "live_carousel_image_3",
                                               avatarImageName: "avatar_3", delegate: self)
        streamsCarouselStackView.addStreamItem(previewImageName: "live_carousel_image_4",
                                               avatarImageName: "avatar_4", delegate: self)
    }
}

// MARK: CarouselItemDelegate

extension HomeViewController: CarouselItemDelegate {
    func didTapCarouselItem(avatarImage: UIImage?, itemView: UIView) {
        tappedAvatarImage = avatarImage
        tappedStreamUrl = (streamsCarouselStackView.subviews.firstIndex(of: itemView) ?? 0) % 2 == 0 ? portraitVideoUrlString : landscapeVideoUrlString
        performSegue(withIdentifier: "showLiveStream", sender: self)
    }
}

// MARK: UIScrollViewDelegate

extension HomeViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        targetContentOffset.pointee.x = getPagedContentOffsetX(scrollView, velocity: velocity, itemWidth: 120, maxIndex: CGFloat(streamsCarouselStackView.subviews.count))
    }
}
