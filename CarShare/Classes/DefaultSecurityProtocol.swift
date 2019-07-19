//
//  DefaultSecurityProtocol.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-18.
//

class DefaultSecurityProtocol: SecurityProtocol {
    var delegate: SecurityProtocolDelegate?

    private let transportProtocol: TransportProtocol
    private let encryptionHandler = AESEncryptionHandler()
    private enum Encryption {
        static let salt: [UInt8] = [
            232,
            96,
            98,
            5,
            159,
            228,
            202,
            239,
        ]

        static let iv: [UInt8] = [
            78,
            53,
            152,
            113,
            108,
            215,
            91,
            102,
            57,
            231,
            14,
            6,
            48,
            41,
            140,
            104
        ]

        static let encryptionKey = EncryptionKey(
            salt: salt,
            iv: iv,
            passphrase: "SUPER_SECRET",
            iterations: 14271)
    }

    init(transportProtocol: TransportProtocol = DefaultTransportProtocol()) {
        self.transportProtocol = transportProtocol
    }

    func open(_ configuration: BLeSocketConfiguration) {
        transportProtocol.delegate = self
        transportProtocol.open(configuration)
    }

    func close() {
        transportProtocol.close()
    }

    func send(_ data: Data) {
        let encrypted = encryptionHandler.encrypt([UInt8](data), with: Encryption.encryptionKey)
        transportProtocol.send(Data(bytes: encrypted, count: encrypted.count))
    }

}

extension DefaultSecurityProtocol: TransportProtocolDelegate {
    func protocolDidOpen(_ protocol: TransportProtocol) {
        delegate?.protocolDidOpen(self)
    }

    func `protocol`(_ protocol: TransportProtocol, didReceive encrypted: Data) {
        let bytes = encryptionHandler.decrypt([UInt8](encrypted), with: Encryption.encryptionKey)
        delegate?.protocol(self, didReceive: Data(bytes: bytes, count: bytes.count))
    }

    func protocolDidSend(_ protocol: TransportProtocol) {
        delegate?.protocolDidSend(self)
    }

    func protocolDidCloseUnexpectedly(_ protocol: TransportProtocol, error: Error) {
        delegate?.protocolDidCloseUnexpectedly(self, error: error)
    }

    func protocolDidFailToSend(_ protocol: TransportProtocol, error: Error) {
        delegate?.protocolDidFailToSend(self, error: error)
    }

    func protocolDidFailToReceive(_ protocol: TransportProtocol, error: Error) {
        delegate?.protocolDidFailToReceive(self, error: error)
    }


}
