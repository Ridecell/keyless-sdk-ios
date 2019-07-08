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
        case scanning(serviceId: CBUUID, characteristicId: CBUUID)
        case connecting(peripheral: CBPeripheral, serviceId: CBUUID, characteristicId: CBUUID)
        case connected(peripheral: CBPeripheral, service: CBService, characteristic: CBCharacteristic)
        case receiving(peripheral: CBPeripheral, data: Data, dataLength: Int, service: CBService, characteristic: CBCharacteristic)
    }

    private var state: State = .idle

    private lazy var central: CBCentralManager = CBCentralManager(delegate: self, queue: nil)

    weak var delegate: Go9ConnectionDelegate?

    func start(serviceID: String, characteristicID: String) {
        state = .scanning(serviceId: CBUUID(string: serviceID), characteristicId: CBUUID(string: characteristicID))
        centralManagerDidUpdateState(central)
    }

    func stop() {
        switch state {
        case .idle:
            break
        case let .connected(peripheral, _, _):
            central.cancelPeripheralConnection(peripheral)
        case let .connecting(peripheral, _, _):
            central.cancelPeripheralConnection(peripheral)
        case let .receiving(peripheral, _, _, _, _):
            central.cancelPeripheralConnection(peripheral)
        case .scanning:
            central.stopScan()
        }
        state = .idle
    }

    func send(_ data: Data) {
        guard case let .connected(peripheral, _, characteristic) = state else {
            return
        }
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }
}

extension Go9Connection: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(#function)
        guard central.state == .poweredOn else {
            return
        }
        guard case let .scanning(serviceID, _) = state else {
            return
        }
        central.scanForPeripherals(withServices: [serviceID], options: nil)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(#function)
        guard case let .scanning(serviceID, characteristicID) = state else {
            return
        }
        state = .connecting(peripheral: peripheral, serviceId: serviceID, characteristicId: characteristicID)
        central.stopScan()
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print(#function)
        guard case let .connecting(peripheral, serviceID, _) = state else {
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
        case let .connecting(_, serviceId, characteristicId):
            start(serviceID: serviceId.uuidString, characteristicID: characteristicId.uuidString)
        case let .connected(_, service, characteristic):
            start(serviceID: service.uuid.uuidString, characteristicID: characteristic.uuid.uuidString)
        case let .receiving(_, _, _, service, characteristic):
            start(serviceID: service.uuid.uuidString, characteristicID: characteristic.uuid.uuidString)
        }
    }
}

extension Go9Connection: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print(#function)
        guard case let .connecting(peripheral, serviceID, characteristicID) = state else {
            return
        }
        guard let service = peripheral.services?.first(where: {$0.uuid == serviceID}) else {
            return
        }
        peripheral.discoverCharacteristics([characteristicID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print(#function)
        guard case let .connecting(peripheral, _, characteristicID) = state else {
            return
        }
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicID }) else {
            return
        }
        state = .connected(peripheral: peripheral, service: service, characteristic: characteristic)
        peripheral.setNotifyValue(true, for: characteristic)
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
        if case let .connected(peripheral, service, _) = state, data.count >= 2 {
            print(Date().timeIntervalSince1970)
            let length = Int(data[0]) << 8 + Int(data[1])
            let messageData = data.advanced(by: 2)
            state = .receiving(peripheral: peripheral, data: messageData, dataLength: length, service: service, characteristic: characteristic)
        } else if case .receiving(let peripheral, var messageData, let length, let service, _) = state {
            messageData.append(data)
            state = .receiving(peripheral: peripheral, data: messageData, dataLength: length, service: service, characteristic: characteristic)
        }
        handleReceivingState()
    }

    private func handleReceivingState() {
        guard case let .receiving(peripheral, messageData, length, service, characteristic) = state else {
            return
        }
        guard messageData.count == length else {
            return
        }
        print(Date().timeIntervalSince1970)
        state = .connected(peripheral: peripheral, service: service, characteristic: characteristic)
        delegate?.go9(self, didReceive: messageData)
//        let message = IncomingMessage(data: messageData)
//        print(message.confirmationToken)
//        peripheral.writeValue(Data(bytes: [UInt8(0x00), UInt8(0x01), UInt8(0x01)], count: 3), for: characteristic, type: .withoutResponse)
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

    func start(serviceID: String, characteristicID: String) {
        connection.delegate = self
        connection.start(serviceID: serviceID, characteristicID: characteristicID)
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
        return responseData == challenge
    }


}
