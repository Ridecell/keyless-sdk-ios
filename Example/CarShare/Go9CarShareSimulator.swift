//
//  Go9CarShareSimulator.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-19.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth

protocol Go9ConnectionDelegate: AnyObject {
    func go9ConnectionDidBegin(_ connection: Go9Connection)
    func go9ConnectionDidEnd(_ connection: Go9Connection, error: Error?)
    func go9(_ go9Connection: Go9Connection, didReceive data: Data)
}

class Go9Connection: NSObject {

    private enum State {
        case idle
        case scanning(serviceId: CBUUID, notifyCharacteristicId: CBUUID, writeCharacteristicId: CBUUID)
        case connecting(peripheral: CBPeripheral, serviceId: CBUUID, notifyCharacteristicId: CBUUID, writeCharacteristicId: CBUUID)
        case connected(peripheral: CBPeripheral, service: CBService, notifyCharacteristic: CBCharacteristic, writeCharacteristic: CBCharacteristic)
        case receiving(peripheral: CBPeripheral, data: Data, dataLength: Int, service: CBService, notifyCharacteristic: CBCharacteristic, writeCharacteristic: CBCharacteristic)
    }

    private var state: State = .idle

    private lazy var central: CBCentralManager = CBCentralManager(delegate: self, queue: nil)

    weak var delegate: Go9ConnectionDelegate?

    func start(serviceID: String, notifyCharacteristicID: String, writeCharacteristicID: String) {
        state = .scanning(
            serviceId: CBUUID(string: serviceID),
        notifyCharacteristicId: CBUUID(string: notifyCharacteristicID),
        writeCharacteristicId: CBUUID(string: writeCharacteristicID))
        centralManagerDidUpdateState(central)
    }

    func stop() {
        switch state {
        case .idle:
            break
        case let .connected(peripheral, _, _, _):
            central.cancelPeripheralConnection(peripheral)
        case let .connecting(peripheral, _, _, _):
            central.cancelPeripheralConnection(peripheral)
        case let .receiving(peripheral, _, _, _, _, _):
            central.cancelPeripheralConnection(peripheral)
        case .scanning:
            central.stopScan()
        }
        state = .idle
    }

    func send(_ data: Data) {
        guard case let .connected(peripheral, _, notifyCharacteristic, writeCharacteristic) = state else {
            return
        }
        peripheral.writeValue(data, for: writeCharacteristic, type: .withoutResponse)
    }
}

extension Go9Connection: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(#function)
        guard central.state == .poweredOn else {
            return
        }
        guard case let .scanning(serviceID, _, _) = state else {
            return
        }
        central.scanForPeripherals(withServices: [serviceID], options: nil)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(#function)
        guard case let .scanning(serviceID, notifyCharacteristicId, writeCharacteristicId) = state else {
            return
        }
        state = .connecting(
            peripheral: peripheral,
            serviceId: serviceID,
            notifyCharacteristicId: notifyCharacteristicId,
            writeCharacteristicId: writeCharacteristicId)
        central.stopScan()
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print(#function)
        guard case let .connecting(peripheral, serviceID, _, _) = state else {
            return
        }
        peripheral.delegate = self
        peripheral.discoverServices([serviceID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print(#function)
        switch state {
        case .idle:
            break
        case .scanning:
            break
        case let .connecting(_, serviceId, notifyCharacteristicId, writeCharacteristicId):
            start(
                serviceID: serviceId.uuidString,
                notifyCharacteristicID: notifyCharacteristicId.uuidString,
                writeCharacteristicID: writeCharacteristicId.uuidString)
        case let .connected(_, service, notifyCharacteristic, writeCharacteristic):
            start(
                serviceID: service.uuid.uuidString,
                notifyCharacteristicID: notifyCharacteristic.uuid.uuidString,
                writeCharacteristicID: writeCharacteristic.uuid.uuidString)
        case let .receiving(_, _, _, service, notifyCharacteristic, writeCharacteristic):
            start(
                serviceID: service.uuid.uuidString,
                notifyCharacteristicID: notifyCharacteristic.uuid.uuidString,
            writeCharacteristicID: writeCharacteristic.uuid.uuidString)
        }
    }
}

extension Go9Connection: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print(#function)
        guard case let .connecting(peripheral, serviceID, notifyCharacteristicId, writeCharacteristicId) = state else {
            return
        }
        guard let service = peripheral.services?.first(where: {$0.uuid == serviceID}) else {
            return
        }
        peripheral.discoverCharacteristics([notifyCharacteristicId, writeCharacteristicId], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print(#function)
        guard case let .connecting(peripheral, _, notifyCharacteristicId, writeCharacteristicId) = state else {
            return
        }
        guard let characteristics = service.characteristics else {
            return
        }
        guard let notifyCharacteristic = characteristics.first(where: { $0.uuid == notifyCharacteristicId }), let writeCharacteristic = characteristics.first(where: { $0.uuid == writeCharacteristicId }) else {
            return
        }
        state = .connected(
            peripheral: peripheral,
            service: service,
            notifyCharacteristic: notifyCharacteristic,
            writeCharacteristic: writeCharacteristic)
        peripheral.setNotifyValue(true, for: notifyCharacteristic)
        delegate?.go9ConnectionDidBegin(self)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print(#function)
        print(error)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print(#function)
        guard let data = characteristic.value else {
            return
        }
        if case let .connected(peripheral, service, notifyCharacteristic, writeCharacteristic) = state, data.count >= 2 {
            print(Date().timeIntervalSince1970)
            let length = Int(data[0]) << 8 + Int(data[1])
            let messageData = data.advanced(by: 2)
            state = .receiving(peripheral: peripheral, data: messageData, dataLength: length, service: service, notifyCharacteristic: notifyCharacteristic, writeCharacteristic: writeCharacteristic)
        } else if case .receiving(let peripheral, var messageData, let length, let service, let notifyCharacteristic, let writeCharacteristic) = state {
            messageData.append(data)
            state = .receiving(
                peripheral: peripheral,
                data: messageData,
                dataLength: length,
                service: service,
                notifyCharacteristic: notifyCharacteristic,
                writeCharacteristic: writeCharacteristic)
        }
        handleReceivingState()
    }

    private func handleReceivingState() {
        guard case let .receiving(peripheral, messageData, length, service, notifyCharacteristic, writeCharacteristic) = state else {
            return
        }
        guard messageData.count == length else {
            return
        }
        print(Date().timeIntervalSince1970)
        state = .connected(peripheral: peripheral, service: service, notifyCharacteristic: notifyCharacteristic, writeCharacteristic: writeCharacteristic)
        delegate?.go9(self, didReceive: messageData)
    }

}

class Go9CarShareSimulator: NSObject {

    private struct IncomingMessage {

        enum Command: UInt8 {
            case checkIn = 0x01
            case checkOut = 0x02
            case lock = 0x03
            case unlock = 0x04
            case locate = 0x05
        }

        let command: Command
        let confirmationToken: String

        init(data: Data) {
            var incomingData = data
            command = Command(rawValue: incomingData.removeFirst())!
            confirmationToken = String(data: incomingData, encoding: .utf8)!
        }
    }

    private var incomingCommand: (incomingMessage: IncomingMessage, challenge: Data)?

    private let connection = Go9Connection()

    func start(serviceID: String, notifyCharacteristicID: String, writeCharacteristicID: String) {
        connection.delegate = self
        connection.start(serviceID: serviceID, notifyCharacteristicID: notifyCharacteristicID, writeCharacteristicID: writeCharacteristicID)
    }

    func stop() {
        connection.stop()
    }

}

extension Go9CarShareSimulator: Go9ConnectionDelegate {
    func go9ConnectionDidBegin(_ connection: Go9Connection) {
        print(#function)
    }

    func go9ConnectionDidEnd(_ connection: Go9Connection, error: Error?) {
        print(#function)
    }

    func go9(_ go9Connection: Go9Connection, didReceive data: Data) {
        print(#function)
        if let incomingCommand = incomingCommand {
            self.incomingCommand = nil
            if verify(incomingCommand.challenge, with: data) {
                connection.send(Data(bytes: [UInt8(0x00), UInt8(0x01), UInt8(0x01)], count: 3))
            } else {
                connection.send(Data(bytes: [UInt8(0x00), UInt8(0x01), UInt8(0x00)], count: 3))
            }
        } else {
            let challenge = generateChallenge()
            incomingCommand = (IncomingMessage(data: data), challenge)
            var outgoingData = Data(bytes: [UInt8(challenge.count >> 8), UInt8(challenge.count & 0xFF)], count: 2)
            outgoingData.append(challenge)
            connection.send(outgoingData)
        }
    }

    private func generateChallenge() -> Data {
        return "CHALLENGE!".data(using: .utf8)!
    }

    private func verify(_ challenge: Data, with responseData: Data) -> Bool {
        return responseData == "CHALLENGE!---PRIVATE_KEY".data(using: .utf8)
    }


}
