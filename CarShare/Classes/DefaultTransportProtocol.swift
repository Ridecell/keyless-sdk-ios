//
//  CarShare.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-07.
//

import Foundation

class DefaultTransportProtocol: TransportProtocol, SocketDelegate {

    private enum State {
        case sending(dataToSend: Data, nextByteIndex: Int)
        case receiving(dataReceived: Data, dataLength: Int)
    }

    private let socket: Socket

    private var outgoing: (data: Data, byteIndex: Int)?

    private var incoming: (data: Data, dataLength: Int)?

    weak var delegate: TransportProtocolDelegate?

    init(socket: Socket) {
        self.socket = socket
    }

    func open(_ configuration: BLeSocketConfiguration) {
        socket.delegate = self
        socket.open(configuration)
    }

    func close() {
        socket.close()
    }

    func send(_ data: Data) {
        outgoing = (data, 0)
        socketDidSend(socket, error: nil)
    }

    func socketDidOpen(_ socket: Socket) {
        delegate?.protocolDidOpen(self)
    }

    func socket(_ socket: Socket, didReceive data: Data) {
        if incoming != nil {
            self.incoming?.data.append(data)
        } else if data.count >= 2 {
            let dataLength = Int(data[0]) << 8 + Int(data[1])
            self.incoming = (data.advanced(by: 2), dataLength)
        } else {
            // some kind of error?
        }
        guard let incoming = incoming else {
            // wtf?
            return
        }
        if incoming.data.count > incoming.dataLength {
            // error
        } else if incoming.data.count == incoming.dataLength {
            let data = incoming.data
            self.incoming = nil
            delegate?.protocol(self, didReceive: data)
        }
    }

    func socketDidCloseUnexpectedly(_ socket: Socket, error: Error) {
        delegate?.protocolDidCloseUnexpectedly(self, error: error)
    }

    func socketDidSend(_ socket: Socket, error: Error?) {
        if let error = error {
            outgoing = nil
            delegate?.protocolDidSend(self, error: error)
            return
        }
        guard let outgoing = outgoing else {
            return
        }
        guard let mtu = socket.mtu else {
            // error
            return
        }
        if let chunk = chunk(outgoing.data, startingAt: outgoing.byteIndex, mtu: mtu) {
            self.outgoing?.byteIndex = chunk.1
            socket.send(chunk.0)
        } else {
            self.outgoing = nil
            delegate?.protocolDidSend(self, error: nil)
        }

    }

    private func chunk(_ data: Data, startingAt index: Int, mtu: Int) -> (Data, Int)? {

        let chunkSize = min(data.count - index, mtu)
        guard chunkSize > 0 else {
            return nil
        }

        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)

        if index == 0 {
            pointer.assign(from: [UInt8(data.count >> 8), UInt8(data.count & 0xFF)], count: 2)
            data.copyBytes(to: pointer.advanced(by: 2), from: index..<chunkSize-2)
            return (Data(bytes: pointer, count: chunkSize), chunkSize - 2)
        } else {
            data.copyBytes(to: pointer, from: index..<index + chunkSize)
            return (Data(bytes: pointer, count: chunkSize), index + chunkSize)
        }
    }
}
//
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
//import CoreBluetooth
//
//class DefaultBLeConnection: NSObject, BLeConnection {
//
//    enum DefaultBLeTransportLayerError: Error {
//        case notConnected
//        case noData
//        case badResponse
//    }
//
//    private enum ConnectionState {
//        case idle
//        case initializing(advertisingData: [String: Any], serviceId: CBUUID, characteristicId: CBUUID)
//        case advertising(characteristic: CBMutableCharacteristic)
//        case connected(characteristic: CBMutableCharacteristic, central: CBCentral)
//    }
//
//    private struct Transport {
//        enum State {
//            case sending(dataToSend: Data, nextByteIndex: Int)
//            case readyForResponse
//            case receiving(dataReceived: Data, dataLength: Int)
//        }
//
//        let state: State
//        let callback: (Result<Data, Error>) -> Void
//    }
//
//    private lazy var peripheral: CBPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)
//
//    private var connectionState: ConnectionState = .idle
//
//    private var transport: Transport? = nil
//
//    weak var delegate: BLeConnectionDelegate?
//
//    var isConnected: Bool {
//        if case .connected = connectionState {
//            return true
//        } else {
//            return false
//        }
//    }
//
//    var transportLayer: BLeTransportLayer?  {
//        if case .connected = connectionState {
//            return self
//        } else {
//            return nil
//        }
//    }
//
//    func connect(_ context: BLeTransportContext) {
//        let serviceId = CBUUID(string: context.serviceID)
//        let advertisingData = [
//            CBAdvertisementDataServiceUUIDsKey: [serviceId]
//        ]
//
//        connectionState = .initializing(
//            advertisingData: advertisingData,
//            serviceId: serviceId,
//            characteristicId: CBUUID(string: context.characteristicID))
//
//        peripheralManagerDidUpdateState(peripheral)
//    }
//
//    func disconnect() {
//        if let transport = transport {
//            self.transport = nil
//            transport.callback(.failure(DefaultBLeTransportLayerError.notConnected))
//        }
//        connectionState = .idle
//        if peripheral.isAdvertising {
//            peripheral.stopAdvertising()
//        }
//        peripheral.removeAllServices()
//    }
//}
//
//extension DefaultBLeConnection: BLeTransportLayer {
//    func send(_ data: Data, callback: @escaping (Result<Data, Error>) -> Void) {
//        guard case let .connected(characteristic, central) = connectionState else {
//            callback(.failure(DefaultBLeTransportLayerError.notConnected))
//            return
//        }
//        guard let chunk = self.chunk(data, startingAt: 0, central: central) else {
//            callback(.failure(DefaultBLeTransportLayerError.noData))
//            return
//        }
//        transport = Transport(state: .sending(dataToSend: data, nextByteIndex: 0), callback: callback)
//
//        if peripheral.updateValue(chunk.0, for: characteristic, onSubscribedCentrals: [central]) {
//            transport = Transport(state: .sending(dataToSend: data, nextByteIndex: chunk.1), callback: callback)
//            peripheralManagerIsReady(toUpdateSubscribers: peripheral)
//        }
//    }
//
//    private func chunk(_ data: Data, startingAt index: Int, central: CBCentral) -> (Data, Int)? {
//
//        let mtu = central.maximumUpdateValueLength
//
//        let chunkSize = min(data.count - index, mtu)
//        guard chunkSize > 0 else {
//            return nil
//        }
//
//        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)
//
//        if index == 0 {
//            print(mtu)
//            pointer.assign(from: [UInt8(data.count >> 8), UInt8(data.count & 0xFF)], count: 2)
//            data.copyBytes(to: pointer.advanced(by: 2), from: index..<chunkSize-2)
//            return (Data(bytes: pointer, count: chunkSize), chunkSize - 2)
//        } else {
//            data.copyBytes(to: pointer, from: index..<index + chunkSize)
//            return (Data(bytes: pointer, count: chunkSize), index + chunkSize)
//        }
//    }
//}
//
//extension DefaultBLeConnection: CBPeripheralManagerDelegate {
//    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
//        guard peripheral.state == .poweredOn else {
//            return
//        }
//        guard case let .initializing(advertisingData, serviceId, characteristicId) = connectionState else {
//            return
//        }
//        log.info("start advertising")
//        let service = CBMutableService(type: serviceId, primary: true)
//        let characteristic = CBMutableCharacteristic(
//            type: characteristicId,
//            properties: [.notify, .writeWithoutResponse],
//            value: nil,
//            permissions: [.writeable])
//        service.characteristics = [characteristic]
//
//        connectionState = .advertising(characteristic: characteristic)
//        peripheral.add(service)
//        peripheral.startAdvertising(advertisingData)
//    }
//
//    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
//        guard case let .advertising(characteristic) = connectionState else {
//            return
//        }
//        connectionState = .connected(characteristic: characteristic, central: central)
//        peripheral.stopAdvertising()
//        delegate?.bleConnectionDidBegin(self, with: self)
//    }
//
//    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
//        guard case let .connected(_, connectedCentral) = connectionState else {
//            return
//        }
//        guard central == connectedCentral else {
//            return
//        }
//        peripheral.removeAllServices()
//        connectionState = .idle
//        delegate?.bleConnectionDidEnd(self, error: nil)
//    }
//
//    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
//        guard let transport = transport, case let .sending(data, nextByteIndex) = transport.state else {
//            return
//        }
//        guard case let .connected(characteristic, central) = connectionState else {
//            self.transport = nil
//            transport.callback(.failure(DefaultBLeTransportLayerError.notConnected))
//            return
//        }
//        guard let chunk = self.chunk(data, startingAt: nextByteIndex, central: central) else {
//            self.transport = Transport(state: .readyForResponse, callback: transport.callback)
//            return
//        }
//        guard peripheral.updateValue(chunk.0, for: characteristic, onSubscribedCentrals: [central]) else {
//            return
//        }
//        self.transport = Transport(state: .sending(dataToSend: data, nextByteIndex: chunk.1), callback: transport.callback)
//        self.peripheralManagerIsReady(toUpdateSubscribers: peripheral)
//    }
//
//    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
//        print(#function)
//        guard let transport = transport else {
//            return
//        }
//        guard case let .connected(_, central) = connectionState else {
//            self.transport = nil
//            transport.callback(.failure(DefaultBLeTransportLayerError.notConnected))
//            return
//        }
//        guard let request = requests.first, request.central == central, let incomingData = request.value else {
//            return
//        }
//        switch transport.state {
//        case .readyForResponse:
//            guard incomingData.count >= 2 else {
//                self.transport = nil
//                transport.callback(.failure(DefaultBLeTransportLayerError.badResponse))
//                return
//            }
//            let dataLength = Int(incomingData[0]) << 8 + Int(incomingData[1])
//            handle(chunk: incomingData.advanced(by: 2), dataCollector: Data(), totalLength: dataLength, callback: transport.callback)
//        case let .receiving(data, dataLength):
//            handle(chunk: incomingData, dataCollector: data, totalLength: dataLength, callback: transport.callback)
//            break
//        default:
//            break
//        }
//    }
//
//    private func handle(chunk: Data, dataCollector data: Data, totalLength: Int, callback: @escaping (Result<Data, Error>) -> Void) {
//        var combinedData = data
//        combinedData.append(chunk)
//        if combinedData.count > totalLength {
//            transport = nil
//            callback(.failure(DefaultBLeTransportLayerError.badResponse))
//        } else if combinedData.count < totalLength {
//            transport = Transport(state: .receiving(dataReceived: combinedData, dataLength: totalLength), callback: callback)
//        } else {
//            transport = nil
//            callback(.success(combinedData))
//        }
//    }
//
//}
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
