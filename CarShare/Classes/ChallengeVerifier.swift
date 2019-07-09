//
//  ChallengeVerifier.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-07-08.
//

import Foundation
import CommonCrypto

class ChallengeVerifier {
    
    //public key
    //MIICCgKCAgEAskV18Q4oDmeeyBNmvnl/gbXUyIHRaRcYmuoPEg2g1TEPXO84E9AZItT5YTlZB6qpyNMX066JNxwcLU/DJj2Ruy0f82ml8GxSZeDy3W4PDnMF4fZ9GY1N9CNeQt8GHkC+RHk8gya8AyHWSeHFlowLfWHeZ8WWkWy3lnouxdXt6Be7Bfrqt84esKnlPQO/VPObpGM1BycaROmhkPQ266A3FZbhc/ra0f5vU733mwxADfYs0lggqKhwpxihfRAarENiceXr9t3IYPThE1kNycLRqKHhhRnlHQlX6EGfLUMPWUCQXeWsDn7lyejd8GIfY+v1FmvHnIb0BY2TTgbY1FTXedsrfaaDojmltoK7MdlsaxKhAgbi1C0loe8bEgQV/iNLtu4dPOt85CKMlJe3f8LjKvqEaYgSdF18yNUM11Su/+TzV/PqGx0F85OV2PpeXvTcb9068ykYNNWUBL7hJX1NUgdY3WdV4wCw2CgrGRe8P1w4pYgeYRmn/rh6r+L9mt+ivEfkt3AwuQynGGkBhai9D1EwV7AX5R+7+nsY0Uysm8oiyL2wpzx2SLUEsicA3O5FGqVFd4z51+4GJEDEpJyInB9+pqidE7CZIdpe+mowSncnm98WgUDj0T8w1Zi+60KnloQphDh7r8dcQxfrAnLryoEZzBcxstpt3u1CcbjH+zECAwEAAQ==
    
    private let publicKey: SecKey?
    
    init(publicKey: String) {
        if let keyData = Data(base64Encoded: publicKey) {
            let parameters : [String : AnyObject] =
                [
                    kSecAttrKeyType as String : kSecAttrKeyTypeRSA,
                    kSecAttrKeyClass as String : kSecAttrKeyClassPublic,
                    kSecAttrKeySizeInBits as String : 4096 as AnyObject,
                    kSecReturnPersistentRef as String : true as AnyObject
            ]
            if #available(iOS 10.0, *) {
                self.publicKey = SecKeyCreateWithData(keyData as CFData, parameters as CFDictionary, nil)
            } else {
                // Fallback on earlier versions
                print("iOS10 not available, verifying fails")
                self.publicKey = nil
            }
        } else {
            self.publicKey = nil
        }
    }
    
    func verify(_ challengeData: Data, withSigned response: Data) -> Bool {
        return verify(challengeData.base64EncodedString(), withSigned: response.base64EncodedString())
    }
    
    func verify(_ base64ChallengeString: String, withSigned response: String) -> Bool {
        var success = false
        if publicKey != nil {
            if let challengeData = Data(base64Encoded: base64ChallengeString) {
                print("Converted challenge string to data")
                //hash the message first
                let digestLength = Int(CC_SHA512_DIGEST_LENGTH)
                let hashBytes = UnsafeMutablePointer<UInt8>.allocate(capacity:digestLength)
                CC_SHA512([UInt8](challengeData), CC_LONG(challengeData.count), hashBytes)
                
                //verify
                guard let responseData = Data(base64Encoded: response) else { return false }
                let status = responseData.withUnsafeBytes {signatureBytes in
                    return SecKeyRawVerify(publicKey!, .PKCS1SHA512, hashBytes, digestLength, signatureBytes, responseData.count)
                }
                if status == noErr {
                    success = true
                }
            }
        }
        return success
    }
    
}
