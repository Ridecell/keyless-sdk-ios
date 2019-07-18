//
//  EncryptionKey.swift
//  CarShare
//
//  Created by Matt Snow on 2019-07-17.
//

public struct EncryptionKey {
    let salt: [UInt8]
    let iv: [UInt8]
    let passphrase: String
    let iterations: UInt32
}
