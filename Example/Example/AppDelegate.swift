//
//  AppDelegate.swift
//  NJCircleLine
//
//  Created by Jin Nagumo on 2018/10/25.
//  Copyright © 2018 Jinbass. All rights reserved.
//

import UIKit
import GoogleMaps

struct Constant {
    static let APIKey = "SPECIFY_YOUR_KEY_HERE"
    static let DirectionKey = "SPECIFY_YOUR_KEY_HERE"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GMSServices.provideAPIKey(Constant.APIKey)
        return true
    }
}

