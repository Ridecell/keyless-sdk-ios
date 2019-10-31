//
//  ChallengeSigner.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-07-08.
//

import CommonCrypto
import Foundation

class ChallengeSigner: Signer {

    func sign(_ challengeData: Data, signingKey: String) -> Data? {
        let unwrappedKey = signingKey.replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "").replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
        guard let keyData = Data(base64Encoded: unwrappedKey, options: .ignoreUnknownCharacters) else {
            return nil
        }
        let parameters: [String: AnyObject] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]

        guard let privateKey = SecKeyCreateWithData(keyData as CFData, parameters as CFDictionary, nil) else {
            return nil
        }
        //hash the message first
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        let hashBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: digestLength)
        CC_SHA256([UInt8](challengeData), CC_LONG(challengeData.count), hashBytes)

        //sign
        let blockSize = SecKeyGetBlockSize(privateKey) //in the case of RSA, modulus is the same as the block size
        var signatureBytes = [UInt8](repeating: 0, count: blockSize)
        var signatureDataLength = blockSize
        let status = SecKeyRawSign(privateKey, .PKCS1SHA256, hashBytes, digestLength, &signatureBytes, &signatureDataLength)
        guard status == noErr else {
            return nil
        }
        return Data(bytes: signatureBytes, count: signatureDataLength)
    }
}
