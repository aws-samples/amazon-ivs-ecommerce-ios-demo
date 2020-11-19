//
//  AppDelegate.swift
//  eCommerce
//
//  Created by Zingis, Uldis on 5/29/20.
//  Copyright © 2020 Twitch. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("‼️ Could not setup AVAudioSession: \(error)")
        }

        return true
    }
}
