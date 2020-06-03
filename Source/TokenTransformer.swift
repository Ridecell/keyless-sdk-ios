//
//  TokenTransformer.swift
//  Keyless
//
//  Created by Marc Maguire on 2019-11-08.
//

import Foundation

protocol TokenTransformer {
    func transform(_ token: String) throws -> KeylessTokenInfo
}

class DefaultKeylessTokenTransformer: TokenTransformer {

    enum TokenTransformerError: Swift.Error, CustomStringConvertible {
        case tokenDecodingFailed
        case base64DecodingFailed

        var description: String {
            switch self {
            case .tokenDecodingFailed:
                return "Failed to decode Car Share token protobuf data."
            case .base64DecodingFailed:
                return "Failed to base64decode the Keyless token."
            }
        }
    }

    func transform(_ token: String) throws -> KeylessTokenInfo {
        guard let decodedData = Data(base64Encoded: token) else {
            throw TokenTransformerError.base64DecodingFailed
        }
        do {
            let token = try CarshareToken(serializedData: decodedData)
            return KeylessTokenInfo(bleServiceUuid: token.bleServiceUuid,
                                    reservationPrivateKey: token.reservationPrivateKey,
                                    reservationModulusHash: token.reservationModulusHash,
                                    tenantModulusHash: token.tenantModulusHash,
                                    reservationToken: token.reservationToken,
                                    reservationTokenSignature: token.reservationTokenSignature)
        } catch {
            throw TokenTransformerError.tokenDecodingFailed
        }
    }
}
