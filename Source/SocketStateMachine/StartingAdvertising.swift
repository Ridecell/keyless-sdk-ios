//
//  StartingAdvertising.swift
//  Keyless
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

extension PeripheralManagerSocket {
    class StartingAdvertising: Pending {

        override func transition() {
            super.transition()
            socket.peripheral.startAdvertising(context.advertisingData)
        }

        func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
            if let error = error {
                socket.state = Failed(socket: socket, error: error)
            } else {
                socket.state = WaitingForSubscription(socket: socket, context: context)
            }
        }
    }
}
