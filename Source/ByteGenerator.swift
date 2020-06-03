//
//  ByteGenerator.swift
//  Keyless_Example
//
//  Created by Marc Maguire on 2019-11-07.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

protocol ByteGenerator {
    func generate(_ size: Int) -> [UInt8]
}

class DefaultByteGenerator: ByteGenerator {
    func generate(_ size: Int) -> [UInt8] {
        let bytes = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 0)

        guard SecRandomCopyBytes(kSecRandomDefault, size, bytes) == errSecSuccess else {
            return []
        }

        let data = Data(bytes: bytes, count: size)
        return [UInt8](data)
    }
}
