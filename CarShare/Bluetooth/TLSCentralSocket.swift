//
//  TLSCentralSocket.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-14.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import CoreBluetooth

class TLSCentralSocket: Socket {

    private lazy var socket: CentralSocket = {
        let socket = CentralSocket()
        socket.delegate = self
        return socket
    }()

    private lazy var context: SSLContext = {
        guard let context = SSLCreateContext(nil, .clientSide, .streamType) else {
            log.error("no context")
            fatalError()
        }

        SSLSetIOFuncs(context, TLSCentralSocket.read, TLSCentralSocket.write)
        let connection = Unmanaged<TLSCentralSocket>.passUnretained(self).toOpaque()

        SSLSetConnection(context, connection)

        return context
    }()

    var socketDelegate: SocketDelegate? {
        return socket.delegate
    }
    weak var delegate: CentralSocketDelegate?

    var readData: [Data] = []

    func scan(for serviceId: String) {
        socket.scan(for: serviceId)
    }

    func stopScanning() {
        socket.stopScanning()
    }

    func open(_ peripheral: CBPeripheral, serviceId: String, characteristicId: String) {
        socket.open(peripheral, serviceId: serviceId, characteristicId: characteristicId)
    }

    func close() {
        socket.close()
    }

    func write(_ data: Data) -> Bool {
        return false
    }

    private static var read: SSLReadFunc = { connection, bytesPointer, length in
        log.error("READ! \(length.pointee)")
        let socket: TLSCentralSocket = Unmanaged<TLSCentralSocket>.fromOpaque(connection).takeUnretainedValue()
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
        let socket: TLSCentralSocket = Unmanaged<TLSCentralSocket>.fromOpaque(connection).takeUnretainedValue()
        let data = Data(bytes: bytesPointer, count: length.pointee)
        return socket.socket.write(data) ? 0 : errSSLWouldBlock
    }

}

extension TLSCentralSocket: CentralSocketDelegate {
    func centralSocket(_ centralSocket: CentralSocket, didDiscover peripheral: CBPeripheral) {
        delegate?.centralSocket(socket, didDiscover: peripheral)
    }

    func socket(_ socket: Socket, didRead data: Data) {
        readData.append(data)
    }

    func socketDidOpen(_ socket: Socket) {
        SSLSetSessionOption(context, .breakOnServerAuth, true)
        handshake()
    }

    private func handshake() {
        var secTrust: SecTrust?
        let certificateValidator = CertificateValidator()


        var handshakeStatus = SSLHandshake(context)
        log.warning(handshakeStatus)
        if handshakeStatus == errSSLPeerAuthCompleted {
            SSLCopyPeerTrust(context, &secTrust)
            if let trust = secTrust {
                // 0 always garunteed to exist
                let cert = SecTrustGetCertificateAtIndex(trust, 0)!
                if !certificateValidator.validate(cert) {
                    log.error("I don't trust this certificate")
                    handshakeStatus = errSSLBadCert
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.handshake()
                    }
                    return
                }
            }
        } else if handshakeStatus == errSSLWouldBlock {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.handshake()
            }
            return
        }

        if handshakeStatus == 0 {
            log.info("ok")
        } else {
            log.error("woops \(handshakeStatus)")
        }
    }

    func socketDidClose(_ socket: Socket) {

    }


}
