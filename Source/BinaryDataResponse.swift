//
//  BinaryDataResponse.swift
//  Keyless
//
//  Created by Marc Maguire on 2019-12-02.
//

import Foundation

struct BinaryDataResponse {
    private enum BinaryDataResponseValues {
        static let dataSize: Int = 10
        static let messageType: UInt8 = 0x22
        static let bodyLength: UInt8 = 0x04
        static let STX: UInt8 = 0x02
        static let ETX: UInt8 = 0x03
    }

    let transmissionSuccess: Bool

    init?(data: Data) {
        guard data.count == BinaryDataResponseValues.dataSize else {
            return nil
        }
        guard [UInt8](data)[0] == BinaryDataResponseValues.STX else {
            return nil
        }
        guard [UInt8](data)[1] == BinaryDataResponseValues.messageType else {
            return nil
        }
        guard [UInt8](data)[2] == BinaryDataResponseValues.bodyLength else {
            return nil
        }
        guard [UInt8](data)[9] == BinaryDataResponseValues.ETX else {
            return nil
        }
        transmissionSuccess = [UInt8](data)[3] == 0x01
    }
}
