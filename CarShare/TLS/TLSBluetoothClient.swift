//
//  TLSClient.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-10.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import RxSwift
import Security

@available(iOS 12.0, *)
class TLSBluetoothClient {
    private let client: BluetoothClient
    private var characteristic: CBCharacteristic?
    private let readQueue = DispatchQueue(label: "ReadQueue")
    private let mainQueue = DispatchQueue.main

    init(client: BluetoothClient) {
        self.client = client
    }

    func scan(serviceId: String) -> Observable<(peripheral: CBPeripheral, advertisementData: [String: Any])> {
        return client.scan(serviceId: serviceId)
    }

    func stopScan() -> Completable {
        return client.stopScan()
    }

    func connect(to peripheral: CBPeripheral, serviceId: String, characteristicId: String) {
        _ = self.client.connect(to: peripheral)
            .flatMap { peripheral in
                self.client.find(serviceId: serviceId, for: peripheral)
            }.flatMap { service in
                self.client.find(characteristicId: characteristicId, for: service)
            }.do(onSuccess: { characteristic in
                self.handshake(on: characteristic)
            })
    }
    private func handshake(on characteristic: CBCharacteristic) {
        guard let context = SSLCreateContext(nil, .clientSide, .streamType) else {
            return
        }
        self.characteristic = characteristic
        let read: SSLReadFunc = { connection, data, length in
            let tlsClient = Unmanaged<TLSBluetoothClient>.fromOpaque(connection).takeUnretainedValue()
            tlsClient.mainQueue.sync {
                guard let characteristic = tlsClient.characteristic else {
                    return
                }
                _ = tlsClient.client.read(characteristic)
                .do(onSuccess: { _ in
                    tlsClient.readQueue.async {

                    }
                })
            }

            return 0
        }
        let write: SSLWriteFunc = { connection, data, length in
            0
        }
        SSLSetIOFuncs(context, read, write)
    }

}
