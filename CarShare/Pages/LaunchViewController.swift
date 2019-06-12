//
//  LaunchViewController.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-03.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreLocation
import RxSwift
import UIKit

class LaunchViewController: UIViewController {

    private enum BLeIdentifier {
        static let service = "cbc01049-b414-473c-a0a3-d6841485e49a".uppercased()
        static let characteristic = "36eefdae-3a30-40b7-acaa-b8eb497cd1ef".uppercased()
    }

    static func initialize(grootWorker: GrootWorker) -> LaunchViewController {
        let viewController = LaunchViewController()
        viewController.grootWorker = grootWorker
        return viewController
    }

    private var grootWorker: GrootWorker!
    private let beaconClient = BeaconClient()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let centralButton = UIButton(type: .roundedRect)
        centralButton.setTitle("Act as central", for: .normal)
        centralButton.addTarget(self, action: #selector(didTapCentral), for: .touchUpInside)
        view.addSubview(centralButton)
        centralButton.translatesAutoresizingMaskIntoConstraints = false
        centralButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        centralButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        let peripheralButton = UIButton(type: .roundedRect)
        peripheralButton.setTitle("Act as peripheral", for: .normal)
        peripheralButton.addTarget(self, action: #selector(didTapPeripheral), for: .touchUpInside)
        view.addSubview(peripheralButton)
        peripheralButton.translatesAutoresizingMaskIntoConstraints = false
        peripheralButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        peripheralButton.topAnchor.constraint(equalTo: centralButton.bottomAnchor).isActive = true

    }

    private func blockPrint() {
        DispatchQueue.global(qos: .default).async {
            var i = 0
            print("start \(i)")
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global(qos: .background).async {
                i += 1
                print("middle \(i)")
                semaphore.signal()
            }
            semaphore.wait()
            i += 1
            print("end \(i)")
        }
    }

    @objc func didTapCentral() {
        grootWorker.fetchGreeting()
            .subscribe { event in
                if case let .success(greeting) = event {
                    let alert = UIAlertController(title: "Ble Message", message: greeting, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    log.info(greeting)
                }
            }
            .disposed(by: disposeBag)
    }

    @objc func didTapPeripheral() {
        print("start")
        let semaphore = DispatchSemaphore(value: 0)

        let uuid = UUID(uuidString: "629e1b55-a1c8-4e68-ba5e-8b8892d5397a")!

        let region = CLBeaconRegion(proximityUUID: uuid, major: 111, minor: 11, identifier: "matt-phone")

        beaconClient.startAdvertising(
            in: region,
            localName: "car-share-beacon-ios",
            serviceId: BLeIdentifier.service,
            characteristicId: BLeIdentifier.characteristic)
            .observeOn(SerialDispatchQueueScheduler(qos: .background))
            .subscribe { event in
                if case let .success(peripheral) = event {
                    log.info("Advertising started! \(peripheral)")
                }
                print("signal")
                semaphore.signal()
            }
            .disposed(by: disposeBag)
        semaphore.wait()
        print("end")
    }
}
