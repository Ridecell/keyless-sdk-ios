//
//  TLSPeripheralSocket.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-14.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth
import CoreLocation


class TLSPeripheralSocket: PeripheralSocket {

    private enum TLSState {
        case idle
        case handshake
        case open
    }

    private lazy var baseSocket: BasePeripheralSocket = {
        let socket = BasePeripheralSocket()
        socket.delegate = self
        return socket
    }()

    var socketDelegate: SocketDelegate? {
        return delegate
    }

    weak var delegate: PeripheralSocketDelegate?

    private var readData: [Data] = []

    private var state: TLSState = .idle
    private lazy var context: SSLContext = {
        guard let context = SSLCreateContext(nil, .serverSide, .streamType) else {
            log.error("no context")
            fatalError()
        }

        SSLSetIOFuncs(context, TLSPeripheralSocket.read, TLSPeripheralSocket.write)
        let connection = Unmanaged<TLSPeripheralSocket>.passUnretained(self).toOpaque()

        SSLSetConnection(context, connection)

        let generator = IdentityGenerator()
        guard let filePath = Bundle.main.url(forResource: "matt-leaf", withExtension: "p12") else {
            fatalError()
        }
        guard let data = try? Data(contentsOf: filePath) else {
            fatalError()
        }
        let identity: SecIdentity = try! generator.generate(data, password: "Asdfghj1!")
        SSLSetCertificate(context, [identity] as CFArray)
        return context
    }()

    func advertiseL2CAPChannel(in region: CLBeaconRegion, serviceId: String, characteristicId: String) {
        return baseSocket.advertiseL2CAPChannel(in: region, serviceId: serviceId, characteristicId: characteristicId)
    }

    func close() {
        return baseSocket.close()
    }

    func write(_ data: Data) -> Bool {
        let writeStatus = data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Bool in
            guard let pointer = buffer.baseAddress else {
                return false
            }
            let processedPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)

            let writeStatus = SSLWrite(self.context, pointer, data.count, processedPointer)
            return writeStatus == 0
        }
        if writeStatus {
            log.info("write ok")
        } else {
            log.error("woops on write")
        }
        return writeStatus
    }
}

extension TLSPeripheralSocket: PeripheralSocketDelegate {
    func socketDidOpen(_ socket: Socket) {
        log.info(#function)
        handshake()
    }

    private func handshake() {
        state = .handshake
        let handshakeStatus = SSLHandshake(context)
        if handshakeStatus == errSSLWouldBlock {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.handshake()
            }
        } else if handshakeStatus == 0 {
            state = .open
            delegate?.socketDidOpen(self)
        }
    }

    private static var read: SSLReadFunc = { connection, bytesPointer, length in
        log.error("READ! \(length.pointee)")
        let socket: TLSPeripheralSocket = Unmanaged<TLSPeripheralSocket>.fromOpaque(connection).takeUnretainedValue()
        guard !socket.readData.isEmpty else {
            length.initialize(to: 0)
            return errSSLWouldBlock
        }
        let data = socket.readData.removeFirst()
        log.info(data.count)
        data.withUnsafeBytes {
            guard let pointer = $0.baseAddress else {
                return
            }
            bytesPointer.copyMemory(from: pointer, byteCount: data.count)
            length.initialize(to: data.count)
        }
        return 0
    }

    private static var write: SSLWriteFunc = { connection, bytesPointer, length in
        log.error("WRITE! \(length.pointee)")
        let socket: TLSPeripheralSocket = Unmanaged<TLSPeripheralSocket>.fromOpaque(connection).takeUnretainedValue()
        let data = Data(bytes: bytesPointer, count: length.pointee)
        return socket.baseSocket.write(data) ? 0 : errSSLWouldBlock
    }

    func socketDidClose(_ socket: Socket) {
        log.warning(#function)
        state = .idle
        delegate?.socketDidClose(self)
    }

    func socket(_ socket: Socket, didRead data: Data) {
        readData.append(data)
        if case .open = state {
            let bytesPointer = UnsafeMutableRawPointer.allocate(byteCount: 1_000_000, alignment: 0)
            let processedPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            let readStatus = SSLRead(context, bytesPointer, 1_000_000, processedPointer)
            if readStatus == 0 {
                log.info("read ok")
                delegate?.socket(self, didRead: Data(bytes: bytesPointer, count: processedPointer.pointee))
            } else {
                log.error("woops on read \(readStatus)")
            }
        }
    }

}
