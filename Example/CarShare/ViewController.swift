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
        serviceID: "1c895756-2de9-4aff-87d5-598b067d4df3",
        characteristicID: "45915f82-6ffe-48f6-9568-0577bbfeca9f")

    private let reservation = Reservation(certificate: "CERT", privateKey: "PRIVATE_KEY")

    override func viewDidLoad() {
        super.viewDidLoad()
        client.delegate = self
    }

    @IBAction func didTapSimulator() {
        client.disconnect()
        simulator.stop()
        simulator.start(serviceID: config.serviceID, characteristicID: config.characteristicID)
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

