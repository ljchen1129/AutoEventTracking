//
//  AppDelegate.swift
//  AutoEventTrackingDemo
//
//  Created by 陈良静 on 2021/3/8.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var shared: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    var window: UIWindow?
    private var enterIntoBackgroundtimer: Date?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }
}
