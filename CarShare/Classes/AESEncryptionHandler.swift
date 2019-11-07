//
//  AESEncryptionHandler.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-07-16.
//

import CommonCrypto
import Foundation

protocol EncryptionHandler: AnyObject {
    func encrypt(_ message: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8]?
    func decrypt(_ encrypted: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8]?
    func encryptionKey(_ salt: [UInt8], initVector: [UInt8], passphrase: String, iterations: Int) -> EncryptionKey
    func encryptionKey() -> EncryptionKey
}

class AESEncryptionHandler: EncryptionHandler {

    private enum Algorithm {
        static let derivedKeyAlgorithm = CCPBKDFAlgorithm(kCCPBKDF2)
        static let iterationAlgorithm = CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512)
        static let derivedKeySize = kCCKeySizeAES256
        static let encryptionAlgorithm = CCAlgorithm(kCCAlgorithmAES)
        static let encryptionOptions = CCOptions(kCCOptionPKCS7Padding)
        static let blockSize = kCCBlockSizeAES128
    }

    // swiftlint:disable:next discouraged_optional_collection
    func encrypt(_ message: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8]? {

        let derivedKey = UnsafeMutablePointer<UInt8>.allocate(capacity: Algorithm.derivedKeySize)

        guard CCKeyDerivationPBKDF(
            Algorithm.derivedKeyAlgorithm,
            encryptionKey.passphrase,
            encryptionKey.passphrase.count,
            encryptionKey.salt,
            encryptionKey.salt.count,
            Algorithm.iterationAlgorithm,
            encryptionKey.iterations,
            derivedKey,
            Algorithm.derivedKeySize) == Int32(kCCSuccess) else {
                return nil
        }

        let allocatedSize = message.count + Algorithm.blockSize

        let encrypted = UnsafeMutableRawPointer.allocate(byteCount: allocatedSize, alignment: 0)
        var encryptedSize = 0
        guard CCCrypt(
            CCOperation(kCCEncrypt),
            Algorithm.encryptionAlgorithm,
            Algorithm.encryptionOptions,
            derivedKey,
            Algorithm.derivedKeySize,
            encryptionKey.initializationVector,
            message,
            message.count,
            encrypted,
            allocatedSize,
            &encryptedSize) == Int32(kCCSuccess) else {
            return nil
        }
        let data = Data(bytes: encrypted, count: encryptedSize)
        return [UInt8](data)
    }

    // swiftlint:disable:next discouraged_optional_collection
    func decrypt(_ encrypted: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8]? {

        let derivedKey = UnsafeMutablePointer<UInt8>.allocate(capacity: Algorithm.derivedKeySize)
        guard CCKeyDerivationPBKDF(
            Algorithm.derivedKeyAlgorithm,
            encryptionKey.passphrase,
            encryptionKey.passphrase.count,
            encryptionKey.salt,
            encryptionKey.salt.count,
            Algorithm.iterationAlgorithm,
            encryptionKey.iterations,
            derivedKey,
            Algorithm.derivedKeySize) == Int32(kCCSuccess) else {
            return nil
        }

        var messageSize = 0
        let allocatedSize = encrypted.count + Algorithm.blockSize
        let message = UnsafeMutableRawPointer.allocate(byteCount: allocatedSize, alignment: 0)
        guard CCCrypt(
            CCOperation(kCCDecrypt),
            Algorithm.encryptionAlgorithm,
            Algorithm.encryptionOptions,
            derivedKey,
            Algorithm.derivedKeySize,
            encryptionKey.initializationVector,
            encrypted,
            encrypted.count,
            message,
            allocatedSize,
            &messageSize) == Int32(kCCSuccess) else {
            return nil
        }
        let data = Data(bytes: message, count: messageSize)
        return [UInt8](data)
    }

    private func generateRandom(_ size: Int) -> [UInt8] {
        let bytes = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 0)

        guard SecRandomCopyBytes(kSecRandomDefault, size, bytes) == errSecSuccess else {
            return []
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

    func encryptionKey(_ salt: [UInt8], initVector: [UInt8], passphrase: String, iterations: Int) -> EncryptionKey {
        return EncryptionKey(
            salt: salt,
            initializationVector: initVector,
            passphrase: passphrase,
            iterations: UInt32(iterations))
    }

    func encryptionKey() -> EncryptionKey {
        return EncryptionKey(
            salt: generateSalt(),
            initializationVector: generateInitializationVector(),
            passphrase: "SUPER_SECRET",
            iterations: 14_271)
    }

}
