//
//  CarShare.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-07.
//

import CoreBluetooth
import Foundation

private protocol TransportMessage {
    var messageData: Data { get }
}

private struct SyncMessage: TransportMessage {
    var messageData: Data {
        let sync: [UInt8] = [0x55]
        return Data(bytes: sync, count: 1)
    }
}

private class AddonMessage: TransportMessage {

    private let messageType: UInt8

    private let body: [UInt8]

    private let isExtendedBodyLength: Bool

    init(messageType: UInt8, body: [UInt8], isExtendedBodyLength: Bool) {
        self.messageType = messageType
        self.body = body
        self.isExtendedBodyLength = isExtendedBodyLength
    }

    private let stx: UInt8 = 0x02

    private let etx: UInt8 = 0x03

    private func checksum(for bytes: [UInt8]) -> [UInt8] {
        var check1: UInt8 = 0
        var check2: UInt8 = 0
        for byte in bytes {
            check1 = check1.addingReportingOverflow(byte).partialValue
            check2 = check2.addingReportingOverflow(check1).partialValue
        }
        return [check1, check2]
    }

    var messageData: Data {
        var bytes = [stx, messageType]
        if isExtendedBodyLength {
            bytes.append(contentsOf: [UInt8(body.count & 0xFF), UInt8(body.count >> 8 & 0xFF)])
        } else {
            bytes.append(contentsOf: [UInt8(body.count & 0xFF)])
        }
        bytes.append(contentsOf: body)
        bytes.append(contentsOf: checksum(for: bytes))
        bytes.append(etx)
        return Data(bytes: bytes, count: bytes.count)
    }
}

private class HandshakeConfirmationMessage: AddonMessage {

    private let deviceID: [UInt8] = [0x5F, 0x10]

    private let flags: [UInt8] = [0x01, 0x00]

    required init() {
        var body = deviceID
        body.append(contentsOf: flags)
        super.init(messageType: 0x81, body: body, isExtendedBodyLength: false)
    }
}

private class ExtendedAppDataMessage: AddonMessage {
    required init(body: [UInt8]) {
        super.init(messageType: 0x88, body: body, isExtendedBodyLength: true)
    }
}

private struct IncomingExtendedAppDataMessage {
    let body: [UInt8]

    init?(messageData: Data) {
        let bytes: [UInt8] = [UInt8](messageData)
        guard bytes.starts(with: [0x02, 0x24]), let last = bytes.last, last == 0x03, bytes.count >= 7 else {
            return nil
        }
        let length = Int(bytes[3]) << 8 + Int(bytes[2])
        guard length + 7 == bytes.count else {
            return nil
        }
        let calculatedChecksum = IncomingExtendedAppDataMessage.checksum(for: Array(bytes[0..<bytes.count - 3]))
        guard Array(bytes[bytes.count - 3..<bytes.count - 1]) == calculatedChecksum else {
            return nil
        }
        body = Array(bytes[4..<bytes.count - 3])
    }

    private static func checksum(for bytes: [UInt8]) -> [UInt8] {
        var check1: UInt8 = 0
        var check2: UInt8 = 0
        for byte in bytes {
            check1 = check1.addingReportingOverflow(byte).partialValue
            check2 = check2.addingReportingOverflow(check1).partialValue
        }
        return [check1, check2]
    }
}

class DefaultTransportProtocol: TransportProtocol, SocketDelegate {

    enum DefaultTransportProtocolError: Error {
        case invalidHandshake
        case malformedData
        case notConnected
        case binaryDataAckFailed
    }

    private enum ConnectionState {
        case idle
        case connecting
        case syncing
        case handshaking
        case connected
    }

    private enum Constants {
        static let binaryDataResponseAckSize = 10
        static let binaryDataResponseAckMsgType: UInt8 = 0x22
    }

    private let socket: Socket
    private let executer: AsyncExecuter

    private var outgoing: (data: Data, byteIndex: Int)?

    private var incoming: (data: Data, dataLength: Int)?

    private var connectionState: ConnectionState = .idle

    weak var delegate: TransportProtocolDelegate?

    init(executer: AsyncExecuter = MainExecuter(), socket: Socket = IOSSocket(peripheral: CBPeripheralManager(delegate: nil, queue: nil))) {
        self.executer = executer
        self.socket = socket
    }

    func open(_ configuration: BLeSocketConfiguration) {
        guard case .idle = connectionState else {
            return
        }
        socket.delegate = self
        connectionState = .connecting
        socket.open(configuration)
    }

    func close() {
        connectionState = .idle
        socket.close()
    }

    func send(_ data: Data) {
        self.send(ExtendedAppDataMessage(body: [UInt8](data)))
    }

    private func send(_ transportMessage: TransportMessage) {
        outgoing = (transportMessage.messageData, 0)
        socketDidSend(socket)
    }

    func socketDidOpen(_ socket: Socket) {
        guard case .connecting = connectionState else {
            return
        }
        connectionState = .syncing
        sendSyncMessage()
    }

    private func sendSyncMessage() {
        guard case .syncing = connectionState else {
            return
        }
        send(SyncMessage())
        executer.after(1) { [weak self] in
            self?.sendSyncMessage()
        }
    }

    func socket(_ socket: Socket, didReceive data: Data) {
        if incoming != nil {
            self.incoming?.data.append(data)
        } else if data.count >= 7 && data[1] == 0x24 {
            let length = Int(data[3]) << 8 + Int(data[2]) + 7
            self.incoming = (data, length)
        } else if data.count == 6 && (data[1] == 0x01 || data[1] == 0x02) {
            self.incoming = (data, data.count)
        } else if data.count == Constants.binaryDataResponseAckSize && data[1] == Constants.binaryDataResponseAckMsgType {
            self.incoming = (data, data.count)
        } else {
            // some kind of error?
        }
        guard let incoming = incoming else {
            return
        }
        if incoming.data.count > incoming.dataLength {
            // error
        } else if incoming.data.count == incoming.dataLength {
            self.incoming = nil
            handleReceived(incoming.data)
        }
    }

    private func handleReceived(_ data: Data) {
        switch connectionState {
        case .idle:
            return
        case .connecting:
            return
        case .syncing:
            let handshake: [UInt8] = [0x02, 0x01, 0x00, 0x03, 0x08, 0x03]
            if data == Data(bytes: handshake, count: 6) {
                connectionState = .handshaking
                send(HandshakeConfirmationMessage())
            } else {
                closeUnexpectedly(with: DefaultTransportProtocolError.invalidHandshake)
            }
        case .handshaking:
            let ack: [UInt8] = [0x02, 0x02, 0x00, 0x04, 0x0A, 0x03]
            if data == Data(bytes: ack, count: ack.count) {
                connectionState = .connected
                delegate?.protocolDidOpen(self)
            } else {
                closeUnexpectedly(with: DefaultTransportProtocolError.invalidHandshake)
            }
        case .connected:
            if let binaryDataResponse = BinaryDataResponse(data: data) {
                if binaryDataResponse.transmissionSuccess {
                    delegate?.protocolDidSend(self)
                } else {
                    delegate?.protocolDidFailToSend(self, error: DefaultTransportProtocolError.binaryDataAckFailed)
                }
            } else {
                if let message = IncomingExtendedAppDataMessage(messageData: data) {
                    delegate?.protocol(self, didReceive: Data(bytes: message.body, count: message.body.count))
                } else {
                    delegate?.protocolDidFailToReceive(self, error: DefaultTransportProtocolError.malformedData)
                }
            }
        }
    }

    func socketDidCloseUnexpectedly(_ socket: Socket, error: Error) {
        closeUnexpectedly(with: error)
    }

    func socketDidSend(_ socket: Socket) {
        guard let outgoing = outgoing else {
            return
        }
        guard let mtu = socket.mtu else {
            delegate?.protocolDidFailToSend(self, error: DefaultTransportProtocolError.notConnected)
            return
        }
        if let chunk = chunk(outgoing.data, startingAt: outgoing.byteIndex, mtu: mtu) {
            self.outgoing?.byteIndex = chunk.1
            socket.send(chunk.0)
        } else {
            self.outgoing = nil
            handleSent()
        }
    }

    func socketDidFailToReceive(_ socket: Socket, error: Error) {
        if case .connected = connectionState {
            self.incoming = nil
            delegate?.protocolDidFailToReceive(self, error: error)
        } else {
            closeUnexpectedly(with: error)
        }

    }

    func socketDidFailToSend(_ socket: Socket, error: Error) {
        if case .connected = connectionState {
            outgoing = nil
            delegate?.protocolDidFailToSend(self, error: error)
        } else {
            closeUnexpectedly(with: error)
        }
    }

    private func handleSent() {
        switch connectionState {
        case .idle:
            return
        case .connecting:
            return
        case .syncing:
            return
        case .handshaking:
            return
        case .connected:
            return
        }
    }

    private func chunk(_ data: Data, startingAt index: Int, mtu: Int) -> (Data, Int)? {

        let chunkSize = min(data.count - index, mtu)
        guard chunkSize > 0 else {
            return nil
        }

        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)

        data.copyBytes(to: pointer, from: index..<index + chunkSize)
        return (Data(bytes: pointer, count: chunkSize), index + chunkSize)
    }

    private func closeUnexpectedly(with error: Error) {
        connectionState = .idle
        incoming = nil
        outgoing = nil
        socket.close()
        delegate?.protocolDidCloseUnexpectedly(self, error: error)
    }
}
