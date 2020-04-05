//
//  Noop.swift
//  CarShare
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

extension PeripheralManagerSocket {
    class Noop: NSObject, SocketState {

        func transition() {}

        func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        }

    }
}
