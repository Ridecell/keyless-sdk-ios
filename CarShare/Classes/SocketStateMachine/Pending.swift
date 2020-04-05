//
//  Pending.swift
//  CarShare
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

extension PeripheralManagerSocket {
    class Pending: NSObject, SocketState, CBPeripheralManagerDelegate {

        struct Context {
            let advertisingData: [String: Any]
            let service: CBMutableService
            let notifyCharacteristic: CBMutableCharacteristic
            let writeCharacteristic: CBMutableCharacteristic
        }

        let socket: PeripheralManagerSocket
        let context: Context

        init(socket: PeripheralManagerSocket, context: Context) {
            self.socket = socket
            self.context = context
        }

        func transition() {
        }

        func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
            if peripheral.state == .poweredOff {
                socket.state = Failed(socket: socket, error: PeripheralManagerSocket.SocketError.bluetoothOff)
            }
        }

        func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
            // If we subscribe, no matter the pending state, we should transition to connected.
            guard characteristic.uuid == context.notifyCharacteristic.uuid else {
                socket.log.w("Unrecognized subscription: \(central) subscribed to \(characteristic)")
                return
            }
            socket.state = Opened(socket: socket, notifyCharacteristic: context.notifyCharacteristic, writeCharacteristic: context.writeCharacteristic, central: central)
        }

    }
}
