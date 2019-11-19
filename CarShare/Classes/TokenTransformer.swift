//
//  TokenTransformer.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-11-08.
//

import Foundation

protocol TokenTransformer {
    func transform(_ token: String) throws -> CarShareTokenInfo
}

class DefaultCarShareTokenTransformer: TokenTransformer {

    enum TokenTransformerError: Error {
        case tokenDecodingFailed
    }

    func transform(_ token: String) throws -> CarShareTokenInfo {
        guard let decodedData = Data(base64Encoded: token) else {
            throw TokenTransformerError.tokenDecodingFailed
        }
        do {
            let token = try CarshareToken(serializedData: decodedData)
            return CarShareTokenInfo(bleServiceUuid: token.bleServiceUuid,
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
