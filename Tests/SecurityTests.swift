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
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    private func generateRandom(_ size: Int) -> [UInt8] {
        let bytes = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 0)


        guard SecRandomCopyBytes(kSecRandomDefault, size, bytes) == errSecSuccess else {
            fatalError()
        }

        let data = Data(bytes: bytes, count: size)
        return [UInt8](data)
    }

    private func generateSalt() -> [UInt8] {
        return generateRandom(8)
    }

    private func generateInitializationVector() -> [UInt8] {
        return generateRandom(16)
    }

    func testEncryption() {
        let hello = "Hello, world!"
        let key = "SUPER_SECRET"

        let security = AESEncryptionHandler()

        let salt = generateSalt()
        let initializationVector = generateInitializationVector()
        let data = [UInt8](hello.data(using: .utf8)!)
        let encryptionKey = EncryptionKey(
            salt: salt,
            initializationVector: initializationVector,
            passphrase: key,
            iterations: 14271)
        let encrypted = security.encrypt(data, with: encryptionKey)!
        let decrypted = security.decrypt(encrypted, with: encryptionKey)!

        XCTAssertEqual(hello, String(bytes: decrypted, encoding: .utf8))
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

        let salt: [UInt8] = [
            232,
            96,
            98,
            5,
            159,
            228,
            202,
            239,
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

        let encryptionKey = EncryptionKey(
            salt: salt,
            initializationVector: initializationVector,
            passphrase: "SUPER_SECRET",
            iterations: 14271)

        let security = AESEncryptionHandler()

        let decrypted = security.decrypt(encrypted, with: encryptionKey)!

        XCTAssertEqual("FOO BAR BAZ", String(bytes: decrypted, encoding: .utf8))
    }
}
