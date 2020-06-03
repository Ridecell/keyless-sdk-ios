//
//  KeylessTokenInfo.swift
//  Keyless
//
//  Created by Marc Maguire on 2019-10-17.
//

import Foundation

struct KeylessTokenInfo: Codable {

    let bleServiceUuid: String
    let reservationPrivateKey: String
    let reservationModulusHash: Data
    let tenantModulusHash: Data
    let reservationToken: Data
    let reservationTokenSignature: Data
}
