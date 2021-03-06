//
//  KeylessMessage.swift
//  Keyless
//
//  Created by Marc Maguire on 2019-10-17.
//

import Foundation

enum DeviceCommandPayload {

    private static var reservationMessageVersion: Int {
        return 1
    }

    private static var commandMessageVersion: Int {
        return 1
    }

    static func build(from keylessTokenInfo: KeylessTokenInfo, commandMessageProto: Data, signedCommandHash: [UInt8]) -> DeviceMessage {
        let deviceMessage = DeviceMessage(reservationSignaturePayload: generateReservationSignaturePayload(from: keylessTokenInfo),
                                          reservationToken: [UInt8](keylessTokenInfo.reservationToken),
                                          commandSignaturePayload: generateCommandSignaturePayload(from: keylessTokenInfo,
                                                                                                   commandMessageProto: commandMessageProto,
                                                                                                   signedCommandHash: signedCommandHash),
                                          commandMessageProto: [UInt8](commandMessageProto))
        return deviceMessage
    }

    private static func generateReservationSignaturePayload(from keylessTokenInfo: KeylessTokenInfo) -> ReservationSignaturePayload {
        return ReservationSignaturePayload(reservationVersion: reservationVersion(from: keylessTokenInfo),
                                           tenantModulusHash: tenantModulusHash(from: keylessTokenInfo),
                                           signedReservationHash: signedReservationHash(from: keylessTokenInfo),
                                           reservationLength: reservationLength(from: keylessTokenInfo),
                                           crc32Reservation: crc32reservation(from: keylessTokenInfo))
    }

    private static func generateCommandSignaturePayload(from keylessTokenInfo: KeylessTokenInfo, commandMessageProto: Data, signedCommandHash: [UInt8]) -> CommandSignaturePayload {
        return CommandSignaturePayload(commandVersion: commandVersion(from: keylessTokenInfo),
                                       reservationPublicKeyHash: reservationPublicKeyHash(from: keylessTokenInfo),
                                       signedCommandHash: signedCommandHash,
                                       commandLength: commandLength(from: commandMessageProto),
                                       crc32Command: crc32command(from: signedCommandHash, commandMessageProto: commandMessageProto))
    }

    private static func reservationVersion(from keylessTokenInfo: KeylessTokenInfo) -> [UInt8] {
        return reservationMessageVersion.reverseBytes().bytes.dropLast(2)
    }

    private static func tenantModulusHash(from keylessTokenInfo: KeylessTokenInfo) -> [UInt8] {
        return [UInt8](keylessTokenInfo.tenantModulusHash.prefix(4))
    }

    private static func signedReservationHash(from keylessTokenInfo: KeylessTokenInfo) -> [UInt8] {
        return [UInt8](keylessTokenInfo.reservationTokenSignature)
    }

    private static func reservationLength(from keylessTokenInfo: KeylessTokenInfo) -> [UInt8] {
        return keylessTokenInfo.reservationToken.count.reverseBytes().bytes.dropLast(2)
    }

    private static func crc32reservation(from keylessTokenInfo: KeylessTokenInfo) -> [UInt8] {
        var input: [UInt8] = [UInt8](keylessTokenInfo.reservationTokenSignature)
        input.append(contentsOf: [UInt8](keylessTokenInfo.reservationToken))
        return CRC32.checksum(bytes: input).byteArray
    }

    private static func commandVersion(from keylessTokenInfo: KeylessTokenInfo) -> [UInt8] {
        return commandMessageVersion.reverseBytes().bytes.dropLast(2)
    }

    private static func reservationPublicKeyHash(from keylessTokenInfo: KeylessTokenInfo) -> [UInt8] {
        return [UInt8](keylessTokenInfo.reservationModulusHash.prefix(4))
    }

    private static func commandLength(from commandMessageProto: Data) -> [UInt8] {
        return commandMessageProto.count.reverseBytes().bytes.dropLast(2)
    }

    private static func crc32command(from signedCommandHash: [UInt8], commandMessageProto: Data) -> [UInt8] {
        var input: [UInt8] = signedCommandHash
        input.append(contentsOf: [UInt8](commandMessageProto))
        return CRC32.checksum(bytes: input).byteArray
    }

}

private enum CRC32 {
    //swiftlint:disable identifier_name
    static var table: [UInt32] = {
        (0...255).map { i -> UInt32 in
            (0..<8).reduce(UInt32(i), { c, _ in
                (c % 2 == 0) ? (c >> 1) : (0xEDB88320 ^ (c >> 1))
            })
        }
    }()

    static func checksum(bytes: [UInt8]) -> UInt32 {
        return ~(bytes.reduce(~UInt32(0), { crc, byte in
            (crc >> 8) ^ table[(Int(crc) ^ Int(byte)) & 0xFF]
        }))
    }
}

//swiftlint:disable operator_usage_whitespace
extension Int {
    var bytes: [UInt8] {
        let v0 = UInt8(((self >> 24) & 0xFF))
        let v1 = UInt8(((self >> 16) & 0xFF))
        let v2 = UInt8(((self >> 8) & 0xFF))
        let v3 = UInt8(((self >> 0) & 0xFF))
        return [v0, v1, v2, v3]
    }

    func reverseBytes() -> Int {
        let v0  = ((self >> 0) & 0xFF)
        let v1  = ((self >> 8) & 0xFF)
        let v2  = ((self >> 16) & 0xFF)
        let v3  = ((self >> 24) & 0xFF)
        return (v0 << 24) | (v1 << 16) | (v2 << 8) | (v3 << 0)
    }
}

extension FixedWidthInteger where Self: UnsignedInteger {

    var byteArray: [UInt8] {
        var endian = bigEndian
        let bytePtr = withUnsafePointer(to: &endian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Self>.size) {
                UnsafeBufferPointer(start: $0, count: MemoryLayout<Self>.size)
            }
        }
        return [UInt8](bytePtr)
    }
}
