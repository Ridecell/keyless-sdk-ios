//
//  DefaultSecurableProtocol.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-07-16.
//

import CommonCrypto

class AESEncryptionHandler: Securable {

    private enum Algorithm {
        static let derivedKeyAlgorithm = CCPBKDFAlgorithm(kCCPBKDF2)
        static let iterationAlgorithm = CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512)
        static let derivedKeySize = kCCKeySizeAES256
        static let encryptionAlgorithm = CCAlgorithm(kCCAlgorithmAES)
        static let encryptionOptions = CCOptions(kCCOptionPKCS7Padding)
        static let blockSize = kCCBlockSizeAES128
    }

    func encrypt(_ message: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8] {

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
                fatalError()
        }

        let allocatedSize = message.count + Algorithm.blockSize

        let encrypted = UnsafeMutableRawPointer.allocate(byteCount: allocatedSize, alignment: 0)
        var encryptedSize = 0
        guard CCCrypt(CCOperation(kCCEncrypt),
                Algorithm.encryptionAlgorithm,
                Algorithm.encryptionOptions,
                derivedKey,
                Algorithm.derivedKeySize,
                encryptionKey.iv,
                message,
                message.count,
                encrypted,
                allocatedSize,
                &encryptedSize) == Int32(kCCSuccess) else {
            fatalError()
        }
        let data = Data(bytes: encrypted, count: encryptedSize)
        return [UInt8](data)
    }

    func decrypt(_ encrypted: [UInt8], with encryptionKey: EncryptionKey) -> [UInt8] {

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
            fatalError()
        }

        var messageSize = 0
        let allocatedSize = encrypted.count + Algorithm.blockSize
        let message = UnsafeMutableRawPointer.allocate(byteCount: allocatedSize, alignment: 0)
        guard CCCrypt(CCOperation(kCCDecrypt),
                Algorithm.encryptionAlgorithm,
                Algorithm.encryptionOptions,
                derivedKey,
                Algorithm.derivedKeySize,
                encryptionKey.iv,
                encrypted,
                encrypted.count,
                message,
                allocatedSize,
                &messageSize) == Int32(kCCSuccess) else {
            fatalError()
        }
        let data = Data(bytes: message, count: messageSize)
        return [UInt8](data)
    }
    
}


