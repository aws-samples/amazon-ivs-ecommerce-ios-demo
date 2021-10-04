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

class PlayerView: UIView {
    private var ivsView: IVSPlayerView?
    var collapsedCenterPosition = CGPoint(x: 0, y: 0)
    var collapsedSize = CGRect(x: 0, y: 0, width: 120, height: 200)
    var expandedSize = CGRect(x: 0, y: 0, width: 120, height: 200)

    @IBOutlet weak var controlsView: UIView!
    @IBOutlet weak var homeButton: UIButton!

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
        ivsView = IVSPlayerView(frame: collapsedSize)
        guard let ivsView = ivsView else {
            return
        }

        self.backgroundColor = .black

        ivsView.backgroundColor = .black
        ivsView.layer.masksToBounds = true
        ivsView.clipsToBounds = true
        ivsView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        ivsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playerTapped)))

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

    private func setSizeForState() {
        switch state {
        case .collapsed:
            self.frame = collapsedSize
            ivsView?.frame = self.frame
            self.layer.cornerRadius = 10
            ivsView?.layer.cornerRadius = 10
            self.center = collapsedCenterPosition
            controlsView.isHidden = true

        case .expanded:
            self.frame = expandedSize
            ivsView?.frame = self.frame
            self.layer.cornerRadius = 30
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
        homeButton.layer.cornerRadius = homeButton.layer.bounds.width / 2
        homeButton.titleLabel?.text = ""
        bringSubviewToFront(controlsView)
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
        controlsView.isHidden.toggle()
        player?.state == .playing ? pausePlayback() : startPlayback()
    }

    @objc private func playerTapped() {
        if state == .collapsed {
            self.state = .expanded
        }
    }

    @IBAction func didTapHomeButton(_ sender: Any) {
        state = .collapsed
    }
}

// MARK: - IVSPlayer.Delegate

extension PlayerView: IVSPlayer.Delegate {

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
