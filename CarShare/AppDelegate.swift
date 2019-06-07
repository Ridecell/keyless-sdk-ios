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
    let beaconClient = BeaconClient()

    func application(
        _: UIApplication,
        // swiftlint:disable discouraged_optional_collection
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = createWindow()

//        beaconClient.startAdvertising("com.geotab.bleRegion")

        validateCertificate("leaf")
        validateCertificate("intermediate")
        validateCertificate("root")
        validateCertificate("fake")

        return true
    }

    private func validateCertificate(_ name: String) {
        guard let filePath = Bundle.main.url(forResource: name, withExtension: "cer") else {
            return
        }
        guard let data = try? Data(contentsOf: filePath) else {
            return
        }
        print(data)
        let validator = CertificateValidator()
        print(validator.validate(data))
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
