//
//  AppDelegate.swift
//  BlackBox
//
//  Created by William Rory Kronmiller on 2/9/19.
//  Copyright © 2019 William Rory Kronmiller. All rights reserved.
//

import UIKit
import AVKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let audioSession = AVAudioSession.sharedInstance()
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Database.shared.initTables(deviceId: UIDevice.current.name)

        // Enable battery life monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true

        // Set up audio session for alerts
        do {
            try audioSession.setCategory(.playback, mode: .default, options: .mixWithOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed \(error).")
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

