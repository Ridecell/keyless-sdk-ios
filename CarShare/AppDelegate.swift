//
//  AppDelegate.swift
//  CarShare
//
//  Created by Matt Snow on 2019-05-30.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import SwiftyBeaver
import UIKit

let log: SwiftyBeaver.Type = {
    let log = SwiftyBeaver.self
    log.addDestination(ConsoleDestination())
    return log
}()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    let container = Registrar.appContainer()

    func application(
        _: UIApplication,
        // swiftlint:disable discouraged_optional_collection
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = createWindow()

        return true
    }

    private func createWindow() -> UIWindow {
        guard let view = container.resolve(LaunchViewController.self) else {
            fatalError("First view is missing!")
        }
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = UIColor.white
        window.rootViewController = UINavigationController(rootViewController: view)
        window.makeKeyAndVisible()
        return window
    }

}
