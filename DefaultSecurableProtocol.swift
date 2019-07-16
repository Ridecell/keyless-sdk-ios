//
//  DefaultSecurableProtocol.swift
//  CarShare
//
//  Created by Marc Maguire on 2019-07-16.
//

import CommonCrypto

class DefaultSecurableProtocol: Securable {
    
    
    func encrypt(_ clearTextData : Data, withPassword password : String) -> Dictionary<String, Data> {
        var setupSuccess = true
        var outDictionary = Dictionary<String, Data>.init()
        var key = Data(repeating:0, count:kCCKeySizeAES256)
        var salt = Data(count: 8)
        let saltCount = salt.count
        salt.withUnsafeMutableBytes { (saltBytes: UnsafeMutablePointer<UInt8>) -> Void in
            let saltStatus = SecRandomCopyBytes(kSecRandomDefault, saltCount, saltBytes)
            if saltStatus == errSecSuccess {
                let passwordData = password.data(using:String.Encoding.utf8)!
                let keyCount = key.count
                key.withUnsafeMutableBytes { (keyBytes : UnsafeMutablePointer<UInt8>) in
                    let derivationStatus = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password, passwordData.count, saltBytes, saltCount, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512), 14271, keyBytes, keyCount)
                    if derivationStatus != Int32(kCCSuccess) {
                        setupSuccess = false
                    }
                }
            } else {
                setupSuccess = false
            }
        }
        
        var iv = Data.init(count: kCCBlockSizeAES128)
        iv.withUnsafeMutableBytes { (ivBytes : UnsafeMutablePointer<UInt8>) in
            let ivStatus = SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, ivBytes)
            if ivStatus != errSecSuccess {
                setupSuccess = false
            }
        }
        
        if (setupSuccess) {
            var numberOfBytesEncrypted : size_t = 0
            let size = clearTextData.count + kCCBlockSizeAES128
            var encrypted = Data.init(count: size)
            let cryptStatus = iv.withUnsafeBytes {ivBytes in
                encrypted.withUnsafeMutableBytes {encryptedBytes in
                    clearTextData.withUnsafeBytes {clearTextBytes in
                        key.withUnsafeBytes {keyBytes in
                            CCCrypt(CCOperation(kCCEncrypt),
                                    CCAlgorithm(kCCAlgorithmAES),
                                    CCOptions(kCCOptionPKCS7Padding),
                                    keyBytes,
                                    key.count,
                                    ivBytes,
                                    clearTextBytes,
                                    clearTextData.count,
                                    encryptedBytes,
                                    size,
                                    &numberOfBytesEncrypted)
                        }
                    }
                }
            }
            if cryptStatus == Int32(kCCSuccess) {
                encrypted.count = numberOfBytesEncrypted
                outDictionary["EncryptionData"] = encrypted
                outDictionary["EncryptionIV"] = iv
                outDictionary["EncryptionSalt"] = salt
            }
        }
        
        return outDictionary;
    }
    
    func decryp(fromDictionary dictionary : Dictionary<String, Data>, withPassword password : String) -> Data {
        var setupSuccess = true
        let encrypted = dictionary["EncryptionData"]
        let iv = dictionary["EncryptionIV"]
        let salt = dictionary["EncryptionSalt"]
        var key = Data(repeating:0, count:kCCKeySizeAES256)
        salt?.withUnsafeBytes { (saltBytes: UnsafePointer<UInt8>) -> Void in
            let passwordData = password.data(using:String.Encoding.utf8)!
            let keyCount = key.count
            key.withUnsafeMutableBytes { (keyBytes : UnsafeMutablePointer<UInt8>) in
                let derivationStatus = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password, passwordData.count, saltBytes, salt!.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512), 14271, keyBytes, keyCount)
                if derivationStatus != Int32(kCCSuccess) {
                    setupSuccess = false
                }
            }
        }
        
        var decryptSuccess = false
        let size = (encrypted?.count)! + kCCBlockSizeAES128
        var clearTextData = Data.init(count: size)
        if (setupSuccess) {
            var numberOfBytesDecrypted : size_t = 0
            let cryptStatus = iv?.withUnsafeBytes {ivBytes in
                clearTextData.withUnsafeMutableBytes {clearTextBytes in
                    encrypted?.withUnsafeBytes {encryptedBytes in
                        key.withUnsafeBytes {keyBytes in
                            CCCrypt(CCOperation(kCCDecrypt),
                                    CCAlgorithm(kCCAlgorithmAES128),
                                    CCOptions(kCCOptionPKCS7Padding),
                                    keyBytes,
                                    key.count,
                                    ivBytes,
                                    encryptedBytes,
                                    (encrypted?.count)!,
                                    clearTextBytes,
                                    size,
                                    &numberOfBytesDecrypted)
                        }
                    }
                }
            }
            if cryptStatus! == Int32(kCCSuccess) {
                clearTextData.count = numberOfBytesDecrypted
                decryptSuccess = true
            }
        }
        
        return decryptSuccess ? clearTextData : Data.init(count: 0)
    }
    
}


