//
//  Idle.swift
//  Keyless
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

extension PeripheralManagerSocket {
    class Idle: NSObject, SocketState {
        let socket: PeripheralManagerSocket

        init(socket: PeripheralManagerSocket) {
            self.socket = socket
        }

        func transition() {
            if socket.peripheral.isAdvertising {
                socket.peripheral.stopAdvertising()
            }
            socket.peripheral.removeAllServices()
        }

        func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        }

    }
}
