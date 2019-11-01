//
//  DeviceMessage.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-10-23.
//

import Foundation

protocol ByteRepresentable {
    var bytes: [UInt8] { get }
}

protocol DataRepresentable {
    var data: Data { get }
}

extension DataRepresentable where Self: ByteRepresentable {
    var data: Data {
        return Data(bytes: bytes, count: bytes.count)
    }
}

struct DeviceMessage {
    let reservationSignaturePayload: ReservationSignaturePayload
    let reservationToken: [UInt8]
    let commandSignaturePayload: CommandSignaturePayload
    let commandMessageProto: [UInt8]
}

extension DeviceMessage: ByteRepresentable, DataRepresentable {
    var bytes: [UInt8] {
        var byteArray: [UInt8] = []
        byteArray.append(contentsOf: reservationSignaturePayload.bytes)
        byteArray.append(contentsOf: reservationToken)
        byteArray.append(contentsOf: commandSignaturePayload.bytes)
        byteArray.append(contentsOf: commandMessageProto)
        return byteArray
    }
}

extension DeviceMessage: CustomStringConvertible {
    var description: String {
        return """
        \(reservationSignaturePayload.description),
        The reservation token has \(reservationToken.count) bytes, -> \(reservationToken),
        \(commandSignaturePayload.description),
        The commandMessageProto has \(commandMessageProto.count) bytes, -> \(commandMessageProto)
        """
    }
}

struct ReservationSignaturePayload {
    let reservationVersion: [UInt8]
    let tenantModulusHash: [UInt8]
    let signedReservationHash: [UInt8]
    let reservationLength: [UInt8]
    let crc32Reservation: [UInt8]
}

extension ReservationSignaturePayload: ByteRepresentable, DataRepresentable {
    var bytes: [UInt8] {
        var byteArray: [UInt8] = []
        byteArray.append(contentsOf: reservationVersion)
        byteArray.append(contentsOf: tenantModulusHash)
        byteArray.append(contentsOf: signedReservationHash)
        byteArray.append(contentsOf: reservationLength)
        byteArray.append(contentsOf: crc32Reservation)
        return byteArray
    }
}

extension ReservationSignaturePayload: CustomStringConvertible {
    var description: String {
        return """
        The reservationVersion has \(reservationVersion.count) bytes, -> \(reservationVersion),
        The tenantModulusHash has \(tenantModulusHash.count) bytes, -> \(tenantModulusHash),
        The signedReservationHash has \(signedReservationHash.count) bytes, -> \(signedReservationHash),
        The reservationLength has \(reservationLength.count) bytes, -> \(reservationLength),
        The crc32Reservation has \(crc32Reservation.count) bytes, -> \(crc32Reservation)
        """
    }
}

struct CommandSignaturePayload {
    let commandVersion: [UInt8]
    let reservationPublicKeyHash: [UInt8]
    let signedCommandHash: [UInt8]
    let commandLength: [UInt8]
    let crc32Command: [UInt8]
}

extension CommandSignaturePayload: ByteRepresentable, DataRepresentable {
    var bytes: [UInt8] {
        var byteArray: [UInt8] = []
        byteArray.append(contentsOf: commandVersion)
        byteArray.append(contentsOf: reservationPublicKeyHash)
        byteArray.append(contentsOf: signedCommandHash)
        byteArray.append(contentsOf: commandLength)
        byteArray.append(contentsOf: crc32Command)
        return byteArray
    }
}

extension CommandSignaturePayload: CustomStringConvertible {
    var description: String {
        return """
        The commandVersion has \(commandVersion.count) bytes, -> \(commandVersion),
        The reservationPublicKeyHash has \(reservationPublicKeyHash.count) bytes, -> \(reservationPublicKeyHash),
        The signedCommandHash has \(signedCommandHash.count) bytes, -> \(signedCommandHash),
        The commandLength has \(commandLength.count) bytes, -> \(commandLength),
        The crc32Command has \(crc32Command.count) bytes, -> \(crc32Command)
        """
    }
}
