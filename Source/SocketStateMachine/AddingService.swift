//
//  AddingService.swift
//  Keyless
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

extension PeripheralManagerSocket {
    class AddingService: Pending {

        override func transition() {
            super.transition()
            context.service.characteristics = [context.notifyCharacteristic, context.writeCharacteristic]
            socket.peripheral.add(context.service)
        }

        func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
            if let error = error {
                socket.state = Failed(socket: socket, error: error)
            } else {
                socket.state = StartingAdvertising(socket: socket, context: context)
            }
        }
    }
}
