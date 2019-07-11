//
//  CarShare.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-07.
//

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
        for  i in 0..<bytes.count {
            check1 = check1.addingReportingOverflow(bytes[i]).partialValue
            check2 = check2.addingReportingOverflow(check1).partialValue
        }
        return [check1, check2]
    }

    var messageData: Data {
        var bytes = [stx, messageType]
        if isExtendedBodyLength {
            bytes.append(contentsOf: [UInt8(body.count >> 8 & 0xFF), UInt8(body.count & 0xFF)])
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

    private let deviceID: [UInt8] = [0x5D, 0x10]

    private let flags: [UInt8] = [0x00, 0x00]

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
        let length = Int(bytes[2]) << 8 + Int(bytes[3])
        guard length + 7 == bytes.count else {
            return nil
        }
        let calculatedChecksum = IncomingExtendedAppDataMessage.checksum(for: Array(bytes[0..<bytes.count-3]))
        guard Array(bytes[bytes.count-3..<bytes.count-1]) == calculatedChecksum else {
            return nil
        }
        body = Array(bytes[4..<bytes.count-3])
    }

    static private func checksum(for bytes: [UInt8]) -> [UInt8] {
        var check1: UInt8 = 0
        var check2: UInt8 = 0
        for  i in 0..<bytes.count {
            check1 = check1.addingReportingOverflow(bytes[i]).partialValue
            check2 = check2.addingReportingOverflow(check1).partialValue
        }
        return [check1, check2]
    }
}

class DefaultTransportProtocol: TransportProtocol, SocketDelegate {

    private enum State {
        case sending(dataToSend: Data, nextByteIndex: Int)
        case receiving(dataReceived: Data, dataLength: Int)
    }

    private enum ConnectionState {
        case idle
        case connecting
        case syncing
        case handshaking
        case connected
    }

    private let socket: Socket

    private var outgoing: (data: Data, byteIndex: Int)?

    private var incoming: (data: Data, dataLength: Int)?

    private var connectionState: ConnectionState = .idle

    weak var delegate: TransportProtocolDelegate?

    init(socket: Socket) {
        self.socket = socket
    }

    func open(_ configuration: BLeSocketConfiguration) {
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
        socketDidSend(socket, error: nil)
    }

    func socketDidOpen(_ socket: Socket) {
        guard case .connecting = connectionState else {
            return
        }
        connectionState = .syncing
        send(SyncMessage())
    }

    func socket(_ socket: Socket, didReceive data: Data) {
        if incoming != nil {
            self.incoming?.data.append(data)
        } else if data.count >= 7 && data[1] == 0x24 {
            let length = Int(data[2]) << 8 + Int(data[3]) + 7
            self.incoming = (data, length)
        } else if data.count == 6 && data[1] == 0x01 {
            self.incoming = (data, 6)
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
            handleReceived(data)
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
                connectionState = .idle
//                tell delegate connection failed....
            }
        case .handshaking:
            return
        case .connected:
            guard let message = IncomingExtendedAppDataMessage(messageData: data) else {
                // tell delegate receive failed....
                return
            }
            delegate?.protocol(self, didReceive: Data(bytes: message.body, count: message.body.count))
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
            handleSent()
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
            connectionState = .connected
            delegate?.protocolDidOpen(self)
        case .connected:
            delegate?.protocolDidSend(self, error: nil)
        }
    }

    private func chunk(_ data: Data, startingAt index: Int, mtu: Int) -> (Data, Int)? {

        let chunkSize = min(data.count - index, mtu)
        guard chunkSize > 0 else {
            return nil
        }

        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSize)

//        if index == 0 {
//            pointer.assign(from: [UInt8(data.count >> 8), UInt8(data.count & 0xFF)], count: 2)
//            data.copyBytes(to: pointer.advanced(by: 2), from: index..<chunkSize-2)
//            return (Data(bytes: pointer, count: chunkSize), chunkSize - 2)
//        } else {
            data.copyBytes(to: pointer, from: index..<index + chunkSize)
            return (Data(bytes: pointer, count: chunkSize), index + chunkSize)
//        }
    }
}
