//
//  WaitingForSubscription.swift
//  CarShare
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

extension PeripheralManagerSocket {
    class WaitingForSubscription: Pending {

        override func transition() {
            socket.executer.after(3) { [weak self] in
                guard let context = self?.context, let socket = self?.socket else {
                    return
                }
                guard let waiting = socket.state as? WaitingForSubscription, waiting == self else {
                    return
                }
                if socket.peripheral.isAdvertising {
                    socket.peripheral.stopAdvertising()
                }
                socket.peripheral.removeAllServices()
                socket.state = AddingService(socket: socket, context: context)
            }
        }
    }
}
