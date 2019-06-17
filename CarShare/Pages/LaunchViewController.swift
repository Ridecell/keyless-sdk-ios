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
import CoreBluetooth

class LaunchViewController: UIViewController {

    private enum BLeIdentifier {
        static let service = "cbc01049-b414-473c-a0a3-d6841485e49b" // "cbc01049-b414-473c-a0a3-d6841485e49a".uppercased()
        static let characteristic = "36eefdae-3a30-40b7-acaa-b8eb497cd1ef".uppercased()
    }

    static func initialize(grootWorker: GrootWorker) -> LaunchViewController {
        let viewController = LaunchViewController()
        return viewController
    }

//    private var grootWorker: GrootWorker!
//    private let beaconClient = BeaconClient()
//    private let disposeBag = DisposeBag()

    let peripheralSocket = TLSPeripheralSocket()
    let centralSocket = TLSCentralSocket()

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
        peripheralButton.topAnchor.constraint(equalTo: centralButton.bottomAnchor, constant: 32).isActive = true

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
        peripheralSocket.close()
        centralSocket.delegate = self
        centralSocket.scan(for: BLeIdentifier.service)
    }

    @objc func didTapPeripheral() {
        centralSocket.close()
        let uuid = UUID(uuidString: "629e1b55-a1c8-4e68-ba5e-8b8892d5397a")!

        let region = CLBeaconRegion(proximityUUID: uuid, major: 111, minor: 11, identifier: "matt-phone")

        peripheralSocket.delegate = self
        peripheralSocket.advertiseL2CAPChannel(in: region, serviceId: BLeIdentifier.service, characteristicId: BLeIdentifier.characteristic)

    }
}

extension LaunchViewController: CentralSocketDelegate, PeripheralSocketDelegate {
    func socketDidOpen(_ socket: Socket) {
        if socket is CentralSocket {
            log.info("central open")
        } else if socket is PeripheralSocket {
            log.info("peripheral open")
        }
    }

    func socketDidClose(_ socket: Socket) {
        if socket is CentralSocket {
            didTapCentral()
        } else if socket is PeripheralSocket {
            didTapPeripheral()
        }
    }

    func socket(_ socket: Socket, didRead data: Data) {
        let string = String(bytes: data, encoding: .utf8)!
        if socket is CentralSocket {
            log.info("central read: \(string)")
        } else if socket is PeripheralSocket {
            log.info("peripheral read: \(string)")
            socket.write("Howdy!".data(using: .utf8)!)
        }
        log.warning("Message! \(string)")
        let alert = UIAlertController(title: string, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func centralSocketDidOpen(_ centralSocket: CentralSocket) {
        centralSocket.write("Hi!".data(using: .utf8)!)
    }

    func centralSocket(_ centralSocket: CentralSocket, didDiscover peripheral: CBPeripheral) {
        centralSocket.stopScanning()
        centralSocket.open(peripheral, serviceId: BLeIdentifier.service, characteristicId: BLeIdentifier.characteristic)
    }
}
