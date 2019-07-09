//
//  ChallengeSigner.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-07-08.
//

import Foundation
import CommonCrypto

class ChallengeSigner {
    
    //private key
    // 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
    
    private let privateKey: SecKey?
    
    init(privateKey: String) {
        //turn base64encoded private key string into SecKey
        if let keyData = Data(base64Encoded: privateKey) {
            let parameters : [String : AnyObject] =
                [
                    kSecAttrKeyType as String : kSecAttrKeyTypeRSA,
                    kSecAttrKeyClass as String : kSecAttrKeyClassPrivate,
                    kSecAttrKeySizeInBits as String : 4096 as AnyObject,
                    kSecReturnPersistentRef as String : true as AnyObject
            ]
            if #available(iOS 10.0, *) {
                self.privateKey = SecKeyCreateWithData(keyData as CFData, parameters as CFDictionary, nil)
            } else {
                // Fallback on earlier versions
                self.privateKey = nil
            }
        } else {
            self.privateKey = nil
        }
        
        
    }
    
    //challenge is bytes / Data
    func sign(_ challengeData: Data) -> Data? {
        guard let privateKey = privateKey else {
            print("No private key")
            return nil
        }
        var signedChallenge: Data?
        //hash the message first
            let digestLength = Int(CC_SHA512_DIGEST_LENGTH)
            let hashBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: digestLength)
            CC_SHA512([UInt8](challengeData), CC_LONG(challengeData.count), hashBytes)
            
            //sign
            let blockSize = SecKeyGetBlockSize(privateKey) //in the case of RSA, modulus is the same as the block size
            var signatureBytes = [UInt8](repeating:0, count:blockSize)
            var signatureDataLength = blockSize
            let status = SecKeyRawSign(privateKey, .PKCS1SHA512, hashBytes, digestLength, &signatureBytes, &signatureDataLength)
            if status == noErr {
                let data = Data(bytes: signatureBytes, count: signatureDataLength)
                signedChallenge = data
            }
        
        return signedChallenge
    }
    
    //challenge is a base64encoded string
    func sign(_ base64ChallengeString: String) -> String? {
        guard let privateKey = privateKey else {
            print("No private key")
            return nil
        }
        var signedChallenge: String?
        //hash the message first
        if let challengeData = Data(base64Encoded: base64ChallengeString) {
            let digestLength = Int(CC_SHA512_DIGEST_LENGTH)
            let hashBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: digestLength)
            CC_SHA512([UInt8](challengeData), CC_LONG(challengeData.count), hashBytes)
            
            //sign
            let blockSize = SecKeyGetBlockSize(privateKey) //in the case of RSA, modulus is the same as the block size
            var signatureBytes = [UInt8](repeating:0, count:blockSize)
            var signatureDataLength = blockSize
            let status = SecKeyRawSign(privateKey, .PKCS1SHA512, hashBytes, digestLength, &signatureBytes, &signatureDataLength)
            if status == noErr {
                let data = Data(bytes: signatureBytes, count: signatureDataLength)
                signedChallenge = data.base64EncodedString()
            }
        }
        
        return signedChallenge
    }
    
}
