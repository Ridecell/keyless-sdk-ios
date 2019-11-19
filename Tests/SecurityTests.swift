//
//  SecurityTests.swift
//  CarShare_Tests
//
//  Created by Matt Snow on 2019-07-17.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
import CommonCrypto
@testable import CarShare

class SecurityTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    private func generateRandom(_ size: Int) -> [UInt8] {
        let bytes = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 0)


        guard SecRandomCopyBytes(kSecRandomDefault, size, bytes) == errSecSuccess else {
            fatalError()
        }

        let data = Data(bytes: bytes, count: size)
        return [UInt8](data)
    }

    private func generateInitializationVector() -> [UInt8] {
        return generateRandom(16)
    }

    func testEncryption() {
        let hello = "Hello, world!"
        let security = AESEncryptionHandler()
        let initializationVector = generateInitializationVector()
        let data = [UInt8](hello.data(using: .utf8)!)
        let encryptionKey = security.encryptionKey(initializationVector)
        let encrypted = security.encrypt(data, with: encryptionKey)!
        let decrypted = security.decrypt(encrypted, with: encryptionKey)!

        XCTAssertEqual(hello, String(bytes: decrypted, encoding: .utf8))
    }
    func testEncryptionFails() {
        let hello = "Hello, world!"
        let security = AESEncryptionHandler()
        let data = [UInt8](hello.data(using: .utf8)!)
        let encryptionKey = EncryptionKey(
            salt: [],
            initializationVector: [],
            passphrase: "",
            iterations: 0)
        XCTAssertNil(security.encrypt(data, with: encryptionKey))
    }


    func testDecryption() {
        let encrypted: [UInt8] = [
            152,
            242,
            236,
            114,
            255,
            70,
            237,
            93,
            32,
            221,
            94,
            228,
            120,
            184,
            185,
            184
        ]

        let initializationVector: [UInt8] = [
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

        let security = AESEncryptionHandler()
        let encryptionKey = security.encryptionKey(initializationVector)

        let decrypted = security.decrypt(encrypted, with: encryptionKey)!

        XCTAssertEqual("FOO BAR BAZ", String(bytes: decrypted, encoding: .utf8))
    }
    
    func testDecryptionFails() {
        let encrypted: [UInt8] = [
            152,
            242,
            236,
            114,
            255,
            70,
            237,
            93,
            32,
            221,
            94,
            228,
            120,
            184,
            185,
            184
        ]
        
        let encryptionKey = EncryptionKey(
            salt: [],
            initializationVector: [],
            passphrase: "",
            iterations: 0)
        
        let security = AESEncryptionHandler()
        
        XCTAssertNil(security.decrypt(encrypted, with: encryptionKey))
    }
    
    func testEncryptionKeyHelperProvidesProperValues() {
        let security = AESEncryptionHandler()
        let encryptionKey = security.encryptionKey([0, 0, 0])
        XCTAssert(encryptionKey.initializationVector == [0, 0, 0])
        XCTAssert(encryptionKey.salt == [232, 96, 98, 5, 159, 228, 202, 239])
        XCTAssert(encryptionKey.passphrase == "SUPER_SECRET")
        XCTAssert(encryptionKey.iterations == 14_271)
    }
}
