//
//  Failed.swift
//  CarShare
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

extension PeripheralManagerSocket {
    class Failed: NSObject, SocketState {
        let socket: PeripheralManagerSocket
        let error: Error

        init(socket: PeripheralManagerSocket, error: Error) {
            self.socket = socket
            self.error = error
        }

        func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {}

        func transition() {
            socket.state = Idle(socket: socket)
            socket.executer.after(0) {
                self.socket.delegate?.socketDidCloseUnexpectedly(self.socket, error: self.error)
            }
        }
    }
}
