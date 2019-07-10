//
//  iOSSocket.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-05.
//

import Foundation
import CoreBluetooth

class IOSSocket: NSObject, Socket {

    enum IOSSocketError: Error {
        case notConnected
        case noData
        case badResponse
    }

    private enum State {
        case idle
        case initializing(advertisingData: [String: Any], serviceId: CBUUID, notifyCharacteristicId: CBUUID, writeCharacteristicId: CBUUID)
        case advertising(notifyCharacteristic: CBMutableCharacteristic, writeCharacteristic: CBMutableCharacteristic)
        case connected(notifyCharacteristic: CBMutableCharacteristic, writeCharacteristic: CBMutableCharacteristic, central: CBCentral)
    }

    private lazy var peripheral: CBPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)

    private var state: State = .idle

    weak var delegate: SocketDelegate?

    var mtu: Int? {
        if case let .connected(_, _, central) = state {
            return central.maximumUpdateValueLength
        } else {
            return nil
        }
    }

    private var dataToSend: Data?

    func open(_ configuration: BLeSocketConfiguration) {
        let serviceId = CBUUID(string: configuration.serviceID)
        let advertisingData = [
            CBAdvertisementDataServiceUUIDsKey: [serviceId]
        ]

        state = .initializing(
            advertisingData: advertisingData,
            serviceId: serviceId,
            notifyCharacteristicId: CBUUID(string: configuration.notifyCharacteristicID),
            writeCharacteristicId: CBUUID(string: configuration.writeCharacteristicID)
        )

        peripheralManagerDidUpdateState(peripheral)
    }

    func close() {

        state = .idle
        if peripheral.isAdvertising {
            peripheral.stopAdvertising()
        }
        peripheral.removeAllServices()
    }

    func send(_ data: Data) {
        guard case .connected = state else {
            delegate?.socketDidSend(self, error: IOSSocketError.notConnected)
            return
        }

        dataToSend = data

        peripheralManagerIsReady(toUpdateSubscribers: peripheral)
    }
}

extension IOSSocket: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else {
            return
        }
        guard case let .initializing(advertisingData, serviceId, notifyCharacteristicId, writeCharacteristicId) = state else {
            return
        }
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
        service.characteristics = [notifyCharacteristic, writeCharacteristic]

        state = .advertising(notifyCharacteristic: notifyCharacteristic, writeCharacteristic: writeCharacteristic)
        peripheral.add(service)
        peripheral.startAdvertising(advertisingData)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard case let .advertising(notifyCharacteristic, writeCharacteristic) = state else {
            return
        }
        state = .connected(notifyCharacteristic: notifyCharacteristic, writeCharacteristic: writeCharacteristic, central: central)
        peripheral.stopAdvertising()
        delegate?.socketDidOpen(self)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        guard case let .connected(_, _, connectedCentral) = state else {
            return
        }
        guard central == connectedCentral else {
            return
        }
        peripheral.removeAllServices()
        state = .idle
        delegate?.socketDidCloseUnexpectedly(self, error: IOSSocketError.notConnected)
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        guard let data = dataToSend else {
            return
        }
        guard case let .connected(notifyCharacteristic, _, central) = state else {
            dataToSend = nil
            delegate?.socketDidSend(self, error: IOSSocketError.notConnected)
            return
        }

        guard peripheral.updateValue(data, for: notifyCharacteristic, onSubscribedCentrals: [central]) else {
            return
        }
        dataToSend = nil
        delegate?.socketDidSend(self, error: nil)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print(#function)
        guard case let .connected(_, _, central) = state else {
            return
        }
        guard let request = requests.first, request.central == central, let data = request.value else {
            return
        }
        delegate?.socket(self, didReceive: data)
    }

}
//
//class DefaultGeotabBLeCarShareClient: GeotabBLeCarShareClient, BLeConnectionDelegate {
//
//    private struct Message {
//
//        enum Command: UInt8 {
//            case checkIn = 0x01
//            case checkOut = 0x02
//            case lock = 0x03
//            case unlock = 0x04
//            case locate = 0x05
//        }
//
//        let command: Command
//        let confirmationToken: String
//
//        var data: Data {
//            guard let tokenData = confirmationToken.data(using: .utf8) else {
//                fatalError("Could not encode confirmation token.")
//            }
//            var data = Data(bytes: [command.rawValue], count: 1)
//            data.append(tokenData)
//            return data
//        }
//
//        var expectedResponseData: Data {
//            return Data(bytes: [0x01], count: 1)
//        }
//    }
//
//    private let connection: BLeConnection
//
//    private var connectCallback: Callback<Void>?
//
//    init(connection: BLeConnection) {
//        self.connection = connection
//    }
//
//    func connect(to vehicle: Vehicle, callback: @escaping Callback<Void>) {
//        connection.delegate = self
//        connectCallback = callback
//        let context = BLeTransportContext(
//            serviceID: vehicle.bleContext.serviceID,
//            characteristicID: vehicle.bleContext.characteristicID)
//        connection.connect(context)
//    }
//
//    func disconnect() {
//        connectCallback = nil
//        if connection.isConnected {
//            connection.disconnect()
//        }
//    }
//
//    func checkIn(with reservation: Reservation, callback: @escaping Callback<Void>) {
//        execute(message: Message(command: .checkIn, confirmationToken: reservation.confirmationToken), callback: callback)
//    }
//
//    func checkOut(with reservation: Reservation, callback: @escaping Callback<Void>) {
//        execute(message: Message(command: .checkOut, confirmationToken: reservation.confirmationToken), callback: callback)
//    }
//
//    func lock(with reservation: Reservation, callback: @escaping Callback<Void>) {
//        execute(message: Message(command: .lock, confirmationToken: reservation.confirmationToken), callback: callback)
//    }
//
//    func unlock(with reservation: Reservation, callback: @escaping Callback<Void>) {
//        execute(message: Message(command: .unlock, confirmationToken: reservation.confirmationToken), callback: callback)
//    }
//
//    func locate(with reservation: Reservation, callback: @escaping Callback<Void>) {
//        execute(message: Message(command: .locate, confirmationToken: reservation.confirmationToken), callback: callback)
//    }
//
//    private func execute(message: Message, callback: @escaping Callback<Void>) {
//        guard let transportLayer = connection.transportLayer else {
//            callback(.failure(.unexpectedSocketClosure))
//            return
//        }
//        let ccr = GeotabBLeCCRLayer()
//        ccr.execute(message.data, signingKey: "", transportLayer: transportLayer) { result in
//            switch result {
//            case .failure:
//                callback(.failure(.invalidState))
//            case let .success(data):
//                if data == message.expectedResponseData {
//                    callback(.success(()))
//                } else {
//                    callback(.failure(.unexpectedResponse))
//                }
//            }
//        }
//    }
//
//    func bleConnectionDidBegin(_ connection: BLeConnection, with transport: BLeTransportLayer) {
//        if let connectCallback = connectCallback {
//            self.connectCallback = nil
//            connectCallback(.success(()))
//        }
//    }
//
//    func bleConnectionDidEnd(_ connection: BLeConnection, error: Error?) {
//        if let connectCallback = connectCallback {
//            self.connectCallback = nil
//            connectCallback(.failure(GeotabBLeCarShareClientError.invalidState))
//        }
//    }
//
//}
//
//
//
//
//class GeotabBLeCCRLayer {
//
//    enum GeotabBLeCCRLayerError: Swift.Error {
//        case malformedChallenge
//    }
//
//    func execute(_ data: Data, signingKey: String, transportLayer: BLeTransportLayer, callback: @escaping (Result<Data, Error>) -> Void) {
//        transportLayer.send(data) { result in
//            switch result {
//            case let .failure(error):
//                callback(.failure(error))
//            case let .success(data):
//                if let challenge = self.transformIntoChallenge(data) {
//                    self.respond(to: challenge, signingKey: signingKey, transportLayer: transportLayer, callback: callback)
//                } else {
//                    callback(.failure(GeotabBLeCCRLayerError.malformedChallenge))
//                }
//            }
//        }
//    }
//
//    private func transformIntoChallenge(_ data: Data) -> String? {
//        return String(data: data, encoding: .utf8)
//    }
//
//    private func sign(_ challenge: String, with signingKey: String) -> Data? {
//        return challenge.data(using: .utf8)
//    }
//
//    private func respond(to challenge: String, signingKey: String, transportLayer: BLeTransportLayer, callback: @escaping (Result<Data, Error>) -> Void) {
//        guard let response = sign(challenge, with: signingKey) else {
//            callback(.failure(GeotabBLeCCRLayerError.malformedChallenge))
//            return
//        }
//        transportLayer.send(response) { result in
//            switch result {
//            case let .failure(error):
//                callback(.failure(error))
//            case let .success(data):
//                callback(.success(data))
//            }
//        }
//    }
//}
