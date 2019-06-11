//
//  InMemoryTLSClient.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-11.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import Foundation
import Security

class InMemoryTLSServer: NSObject {

    func handleConnectionRequest(_ client: InMemoryTLSClient) {
        guard let context = SSLCreateContext(nil, .serverSide, .streamType) else {
            return
        }
        guard let filePath = Bundle.main.url(forResource: "matt-leaf", withExtension: "cer") else {
            return
        }
        guard let data = try? Data(contentsOf: filePath) else {
            return
        }

        let certificate = SecCertificateCreateWithData(nil, data as CFData)
        SSLSetCertificate(context, [certificate] as CFArray)
    }

    func read() -> Data {
        print("read")
        return Data()
    }

    func write(_ data: Data) {
        print("write \(data)")
    }

    func handleRequest(_ client: InMemoryTLSClient) -> Data {
        return Data()
    }
}

class InMemoryTLSClient: NSObject {

    private let server = InMemoryTLSServer()

    func connect() {
        guard let context = SSLCreateContext(nil, .clientSide, .streamType) else {
            return
        }

        let read: SSLReadFunc = { (connection: SSLConnectionRef, bytesPointer: UnsafeMutableRawPointer, length: UnsafeMutablePointer<Int>) in
            let client = Unmanaged<InMemoryTLSClient>.fromOpaque(connection).takeUnretainedValue()

            let data = client.server.read()
            bytesPointer.storeBytes(of: data, as: Data.self)
            length.initialize(to: data.count)

            return 0
        }
        let write: SSLWriteFunc = { (connection: SSLConnectionRef, bytesPointer: UnsafeRawPointer, length: UnsafeMutablePointer<Int>) in
            let client = Unmanaged<InMemoryTLSClient>.fromOpaque(connection).takeUnretainedValue()

            let data = Data(bytes: bytesPointer, count: length.pointee)
            client.server.write(data)

            return 0
        }
        SSLSetIOFuncs(context, read, write)
        let connection = Unmanaged<InMemoryTLSClient>.passUnretained(self).toOpaque()
        _ = SSLSetConnection(context, connection)
        let handshakeStatus = SSLHandshake(context)
        print(handshakeStatus)

    }

}
