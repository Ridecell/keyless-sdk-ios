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
