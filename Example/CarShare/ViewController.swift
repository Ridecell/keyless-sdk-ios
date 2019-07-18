//
//  ViewController.swift
//  CarShare
//
//  Created by msnow-bsm on 07/05/2019.
//  Copyright (c) 2019 msnow-bsm. All rights reserved.
//

import UIKit
import CarShare

class ViewController: UIViewController, CarShareClientConnectionDelegate {
    private let simulator = Go9CarShareSimulator()

    private let client = DefaultCarShareClient()

    private let config = BLeSocketConfiguration(
        serviceID: "42B20191-092E-4B85-B0CA-1012F6AC783F",
        notifyCharacteristicID: "430F2EA3-C765-4051-9134-A341254CFD00",
        writeCharacteristicID: "906EE7E0-D8DB-44F3-AF54-6B0DFCECDF1C")

    private let reservation = Reservation(certificate: "CERT", privateKey: "PRIVATE_KEY")

    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
    }

    @IBAction func didTapSimulator() {
        client.disconnect()
        simulator.stop()
        simulator.start(
            serviceID: config.serviceID,
            notifyCharacteristicID: config.notifyCharacteristicID,
            writeCharacteristicID: config.writeCharacteristicID)
    }

    @IBAction func didTapCheckIn() {
        simulator.stop()
        client.disconnect()
        client.connect(config)
    }

    func clientDidConnect(_ client: CarShareClient) {
        client.checkIn(with: reservation) {
            switch $0 {
            case let .failure(error):
                print("CHECK IN FAILED: \(error)")
            case .success:
                print("CHECKED IN")
            }
        }
    }

    func clientDidDisconnectUnexpectedly(_ client: CarShareClient, error: Error) {
        print("SOMETHING WENT WRONG: \(error)")
    }
}

