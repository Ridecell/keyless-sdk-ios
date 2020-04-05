//
//  Opening.swift
//  CarShare
//
//  Created by Matt Snow on 2020-03-30.
//

import CoreBluetooth

extension PeripheralManagerSocket {
    class Opening: Pending {

        convenience init(socket: PeripheralManagerSocket, advertisingData: [String: Any], serviceId: CBUUID, notifyCharacteristicId: CBUUID, writeCharacteristicId: CBUUID) {
            let service = CBMutableService(type: serviceId, primary: true)

            let notifyCharacteristic = CBMutableCharacteristic(
                type: notifyCharacteristicId,
                properties: [.notify],
                value: nil,
                permissions: [])
            let writeCharacteristic = CBMutableCharacteristic(
                type: writeCharacteristicId,
                properties: [.writeWithoutResponse],
                value: nil,
                permissions: [.writeable])
            self.init(socket: socket, context: Context(advertisingData: advertisingData, service: service, notifyCharacteristic: notifyCharacteristic, writeCharacteristic: writeCharacteristic))
        }

        override func transition() {
            super.transition()
            peripheralManagerDidUpdateState(socket.peripheral)
        }

        override func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
            super.peripheralManagerDidUpdateState(peripheral)

            guard peripheral.state == .poweredOn else {
                return
            }

            socket.state = AddingService(socket: socket, context: context)
        }
    }
}
