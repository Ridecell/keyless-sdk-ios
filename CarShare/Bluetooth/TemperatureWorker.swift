//
//  TemperatureWorker.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-03.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import RxSwift

class TemperatureWorker {

    private enum Identifier {
        static let service = "1809"
        static let characteristic = "2A1C"
    }

    private let bluetoothClient: BluetoothClient

    init(bluetoothClient: BluetoothClient) {
        self.bluetoothClient = bluetoothClient
    }

    func printTemperature() -> Single<Float?> {
        return bluetoothClient
            .scan(serviceId: Identifier.service)
            .take(1).asSingle()
            .flatMap { peripheral in
                self.bluetoothClient.stopScan()
                    .andThen(self.connectToCharacteristic(for: peripheral))
            }
            .flatMap(self.readTemperature)
    }

    private func connectToCharacteristic(for peripheral: CBPeripheral) -> Single<CBCharacteristic> {
        return bluetoothClient.connect(to: peripheral)
            .flatMap {
                self.bluetoothClient.find(serviceId: Identifier.service, for: $0)
            }
            .flatMap {
                self.bluetoothClient.find(characteristicId: Identifier.characteristic, for: $0)
            }
    }

    private func readTemperature(from characteristic: CBCharacteristic) -> Single<Float?> {
        return bluetoothClient.read(characteristic)
            .map { value in
                guard let value = characteristic.value, value.count == 5 else {
                    return nil
                }
                let flags = value[0]
                print(flags)
                print("unit: \((flags & 0b1) == 0 ? "C" : "F")")
                print("timestamp: \((flags & 0b10) == 0 ? "Not Available" : "Available")")
                print("temp type: \((flags & 0b100) == 0 ? "Not Available" : "Available")")
                return Float(value[1]) / 10
            }

    }
}
