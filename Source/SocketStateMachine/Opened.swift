//
//  Opened.swift
//  Keyless
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

extension PeripheralManagerSocket {
    class Opened: Connected {

        override func transition() {
            super.transition()
            if socket.peripheral.isAdvertising {
                socket.peripheral.stopAdvertising()
            }
            socket.state = Connected(socket: socket, notifyCharacteristic: notifyCharacteristic, writeCharacteristic: writeCharacteristic, central: central)
            socket.executer.after(0) {
                self.socket.delegate?.socketDidOpen(self.socket)
            }
        }
    }
}
