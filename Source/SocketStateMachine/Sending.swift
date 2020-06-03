//
//  Sending.swift
//  Keyless
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

extension PeripheralManagerSocket {
    class Sending: Connected {
        let data: Data

        init(socket: PeripheralManagerSocket, notifyCharacteristic: CBMutableCharacteristic, writeCharacteristic: CBMutableCharacteristic, central: CBCentral, data: Data) {
            self.data = data
            super.init(socket: socket, notifyCharacteristic: notifyCharacteristic, writeCharacteristic: writeCharacteristic, central: central)
        }

        override func transition() {
            super.transition()
            peripheralManagerIsReady(toUpdateSubscribers: socket.peripheral)
        }

        func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
            if peripheral.updateValue(data, for: notifyCharacteristic, onSubscribedCentrals: [central]) {
                socket.state = Connected(socket: socket, notifyCharacteristic: notifyCharacteristic, writeCharacteristic: writeCharacteristic, central: central)
                socket.log.d("didSend: \([UInt8](data))")
                socket.executer.after(0) {
                    self.socket.delegate?.socketDidSend(self.socket)
                }
            }
        }
    }
}
