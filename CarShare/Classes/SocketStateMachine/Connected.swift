//
//  Connected.swift
//  CarShare
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

extension PeripheralManagerSocket {
    class Connected: NSObject, SocketState, CBPeripheralManagerDelegate {
        let socket: PeripheralManagerSocket
        let notifyCharacteristic: CBMutableCharacteristic
        let writeCharacteristic: CBMutableCharacteristic
        let central: CBCentral

        init(socket: PeripheralManagerSocket, notifyCharacteristic: CBMutableCharacteristic, writeCharacteristic: CBMutableCharacteristic, central: CBCentral) {
            self.socket = socket
            self.notifyCharacteristic = notifyCharacteristic
            self.writeCharacteristic = writeCharacteristic
            self.central = central
        }

        func transition() {
        }

        func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
            if peripheral.state == .poweredOff {
                socket.state = Failed(socket: socket, error: PeripheralManagerSocket.SocketError.lostConnection)
            }
        }

        func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
            guard characteristic.uuid == notifyCharacteristic.uuid else {
                socket.log.w("Unrecognized characteristic for unsubscription: \(central) unsubscribed from \(characteristic)")
                return
            }
            guard central == self.central else {
                socket.log.w("Unrecognized characteristic for unsubscription: \(central) unsubscribed from \(characteristic)")
                return
            }
            socket.state = Failed(socket: socket, error: PeripheralManagerSocket.SocketError.lostConnection)
        }

        func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
            guard let request = requests.first, let data = request.value else {
                return
            }
            guard request.characteristic == writeCharacteristic else {
                socket.log.w("Unrecognized characteristic for write request: \(request.central) requested write to \(request.characteristic)")
                return
            }
            guard request.central == central else {
                socket.log.w("Unrecognized central for write request: \(request.central) requested write to \(request.characteristic)")
                return
            }
            socket.log.d("didReceive: \([UInt8](data))")
            socket.executer.after(0) {
                self.socket.delegate?.socket(self.socket, didReceive: data)
            }
        }

    }
}
