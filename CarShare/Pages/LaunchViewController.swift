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
        static let service = "cbc01049-b414-473c-a0a3-d6841485e49a"
        static let characteristic = "36eefdae-3a30-40b7-acaa-b8eb497cd1ef"
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
        let uuid = UUID()
        let region = CLBeaconRegion(
            proximityUUID: uuid,
            identifier: uuid.uuidString)

        beaconClient.startAdvertising(
            in: region,
            localName: "car-share-beacon-ios",
            serviceId: BLeIdentifier.service,
            characteristicId: BLeIdentifier.characteristic)
            .subscribe { event in
                if case let .success(peripheral) = event {
                    log.info("Advertising started! \(peripheral)")
                }
            }
            .disposed(by: disposeBag)
    }
}
