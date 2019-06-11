//
//  GrootWorker.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-10.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import RxSwift

class GrootWorker {

    private enum Identifier {
        static let service = "cbc01049-b414-473c-a0a3-d6841485e49a"
        static let characteristic = "36eefdae-3a30-40b7-acaa-b8eb497cd1ef"
    }

    private let bluetoothClient: BluetoothClient

    init(bluetoothClient: BluetoothClient) {
        self.bluetoothClient = bluetoothClient
    }

    func fetchGreeting() -> Single<String> {
        return bluetoothClient
            .scan(serviceId: Identifier.service)
            .take(1)
            .asSingle()
            .flatMap { arg in
                let (peripheral, _) = arg
                return self.connectToCharacteristic(for: peripheral)
                    .flatMap(self.readGreeting)
            }
    }

    private func connectToCharacteristic(for peripheral: CBPeripheral) -> Single<CBCharacteristic> {
        log.verbose("connecting to \(peripheral.identifier)")
        return bluetoothClient.connect(to: peripheral)
            .flatMap {
                self.bluetoothClient.find(serviceId: Identifier.service, for: $0)
            }
            .flatMap {
                log.info("find characteristic: \(Identifier.characteristic)")
                return self.bluetoothClient.find(characteristicId: Identifier.characteristic, for: $0)
            }
    }

    private func readGreeting(from characteristic: CBCharacteristic) -> Single<String> {
        return bluetoothClient.read(characteristic)
            .map { value in
                dump(value)
                guard let value = value else {
                    return ""
                }
                return String(data: value, encoding: .utf8) ?? ""
            }

    }
}
