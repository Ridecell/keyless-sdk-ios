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
        return generateRandom(kCCBlockSizeAES128)
    }

    func testEncryption() {
        let hello = "Hello, world!"
        let key = "SUPER_SECRET"

        let security = AESEncryptionHandler()

        print(kCCKeySizeAES256)
        let salt = generateSalt()
        dump(salt)
        let iv = generateInitializationVector()
        dump(iv)
        let data = [UInt8](hello.data(using: .utf8)!)
        let encryptionKey = EncryptionKey(salt: salt, iv: iv, passphrase: key, iterations: 14271)
        let encrypted = security.encrypt(data, with: encryptionKey)

        dump(encrypted)

        let decrypted = security.decrypt(encrypted, with: encryptionKey)

        dump(String(bytes: decrypted, encoding: .utf8))
        XCTAssertEqual(hello, String(bytes: decrypted, encoding: .utf8))
    }
}
