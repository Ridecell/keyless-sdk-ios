//
//  ChallengeSignerTests.swift
//  CarShare_Tests
//
//  Created by Marc Maguire on 2019-10-21.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import CommonCrypto
import XCTest
@testable import CarShare

class ChallengeSignerTests: XCTestCase {
    
    private var sut: Signer!
    private var signableData: Data!
    private var publicKey: String!
    private var privateKey: String!

    override func setUp() {
        sut = ChallengeSigner()
        publicKey = "MIIBITANBgkqhkiG9w0BAQEFAAOCAQ4AMIIBCQKCAQBZBrdVNXjgKX3rd++2yoJxiWIAJgHkDAG3H/a4SJrTe3aSXJb1dhrZTW2yZ58Tsp0Mcv/gQlfsFglxHBKhoNuOHJvSq4ROqDs/lYLKaUqXqQRqyPmMGnie4J/DbVCVRX2Aw87xM+wa+GrMhaF22ZnbAzdqEW+0uj96djvB2ec4K2fOFAd2xrXnZ934MANL113OyEIHBwd3e1a4+SoyGLIwbEh0/NzRIYi6oZrVRdlWjj2PHMlobBw6RkRw7gWGhqXEwbS0wzZAALvi301CwhBFwCBSk1utWyIR/Qok/wz8Z6zTLuERSA2xyfR8838efdSBaoAZLbzqZgn+d/R3k9pNAgMBAAE="
        privateKey = """
                    -----BEGIN RSA PRIVATE KEY-----
                    MIIEowIBAAKCAQBZBrdVNXjgKX3rd++2yoJxiWIAJgHkDAG3H/a4SJrTe3aSXJb1
                    dhrZTW2yZ58Tsp0Mcv/gQlfsFglxHBKhoNuOHJvSq4ROqDs/lYLKaUqXqQRqyPmM
                    Gnie4J/DbVCVRX2Aw87xM+wa+GrMhaF22ZnbAzdqEW+0uj96djvB2ec4K2fOFAd2
                    xrXnZ934MANL113OyEIHBwd3e1a4+SoyGLIwbEh0/NzRIYi6oZrVRdlWjj2PHMlo
                    bBw6RkRw7gWGhqXEwbS0wzZAALvi301CwhBFwCBSk1utWyIR/Qok/wz8Z6zTLuER
                    SA2xyfR8838efdSBaoAZLbzqZgn+d/R3k9pNAgMBAAECggEACo4LSmTukdUZgsNT
                    fl6AHKnnHpFjBACQa3+0pqClCpHGuw+TLkL0Z/MQIGi8qX8xs3om8BWtiuYJ9IkZ
                    hGQn469soguHwjOb4qv9N7ZIC7cUOPze6UdyKZQEHQ1m0mvMt2l/rYU0ZvYw41Ks
                    lAS0gwzckwzCK7ExOXmvGAqXqUcIRupvhE5YyVx7jhPBK0Z4/zpr+NXzF4Qc0esy
                    g5hCCk3lF+3a1PVULs7JuSUj+goxtcWuWVYLNGKfVPzRDSNfjUWk42oNJOJ2bchx
                    qhtOrt/KQ032vmd7oUKqiLasmgWs8RzFeQKcXzbBEl/H3KCTNDLMSADEcygaQ69S
                    S9vimQKBgQCg5Kseit8jVgmgupaGFjf5M6HAJ6nqFy/q6n0whGLu3oI/VdRYWBU6
                    +uxmIgLmYBaIs3Ts/Qsg6W2zzCcmCNgvE0bxhDOKoLevBw7//iuy5U/cHI8uCt4T
                    0ggFRK+XMCiGjZc3YfGQGRDJEnOWdWaAxymsMDFU0iUfaF2ilH0MVwKBgQCNprN8
                    9kEnK2M3jiU1z9PWBTGam365KxP+KDtibLZvFpx/aHeyknpgMd73KDIb6QT+EWE3
                    2PLJ0J77iY66ygoIwpKcaKweUEp05d3k8FebcX1XjEPDy8v/APPGGWatdKnuw0M7
                    lRvuSCnGGVsACiOnptB2P2eq+umPMp2l7fSn+wKBgQCLSMp222QGtDILidxLYiq8
                    upz5u5yWAdLCvJL6EHGRNuFssQHuJPrkH1vNov39sAtx9mFv1DPxHwOQVllBzQBR
                    6I9O/9Ka3T2G8UZkCQaNjYTQGY0+H7xXTkkRPoAAE3nR2fuhv1GfHIPyfd3A0AuX
                    ylLiNKpQMsheYzxEReXnawKBgD2bLd8AXu/BMAKegNJ5lAE1+w/p5uBzuttD9ifl
                    bia8Z84FymFQ0YZ6yiUmRzzaSICTYHvgkB9z62Esv3W/n0OWFBuQbqM0el2DB9Gl
                    MgT6A/CKoYJLZWp/qIYU0BJKdgnQxLHqNN6aZgixSGGpBz7ID0wOYXD8dY4BDo13
                    A3v3AoGBAIIlWAO2Y529ulxiJiosDpzvSHoTf3qZaP+qWFeY6O4m0mGdROk4zX5M
                    vI4ug1OPRU2Qsl6dru8eCKL/kBgNFsSFSdorKS+iCaf4t7EMtt8ZlwdShwKy7c3f
                    aFlYpKI1/KD+84Tgrzj42HkAuyKgP7XJRt6sWOhV08zQ4ovwrPJl
                    -----END RSA PRIVATE KEY-----
                    """
        signableData = "SignME".data(using: .utf8)
    }

    override func tearDown() {
        sut = nil
        publicKey = nil
        privateKey = nil
        signableData = nil
    }

    func testSignatureIsValid() {
        let verifier = ChallengeVerifier(publicKey: publicKey)
        guard let signedData = sut.sign(signableData.base64EncodedData(), signingKey: privateKey) else {
            XCTFail()
            return
        }
        XCTAssertTrue(verifier.verify(signableData.base64EncodedData(), withSigned: signedData))
    }
    
    func testVerificationFailsIfPublicKeyIsWrong() {
        let verifier = ChallengeVerifier(publicKey: "MIIBITANBgkqhkiG9w0BAQEFAAOCAQ4AMIIBCQKCAQBZBrdVNXjgKX3rd++2yoJxiWIAJgHkDAG3H/a4SJrTe3aSXJb1dhrZTW2yZ58Tsp0Mcv/gQlfsFglxHBKhoNuOHJvSq4ROqDs/lYLKaUqXqQRqyPmMGnie4J/DbVCVRX2Aw87xM+wa+GrMhaF22ZnbAzdqEW+0uj96djvB2ec4K2fOFAd2xrXnZ934MANL113OyEIHBwd3e1a4+SoyGLIwbEh0/NzRIYi6oZrVRdlWjj2PHMlobBw6RkRw7gWGhqXEwbS0wzZAALvi301CwhBFwCBSk1utWyIR/Qok/wz8Z6zTLuERSA2xyfR8838efdSBaoAZLbzqZgn+d/R3k9pNAgMBEAE=")

        guard let signedData = sut.sign(signableData.base64EncodedData(), signingKey: privateKey) else {
            XCTFail()
            return
        }
        XCTAssertFalse(verifier.verify(signableData.base64EncodedData(), withSigned: signedData))
        
    }
    
    func testVerificationFailsIfPrivateKeyIsWrong() {
        let verifier = ChallengeVerifier(publicKey: publicKey)
        let incorrectPrivateKey = """
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAgJ1JiI2lWDbS77r67iER/mPr9jhPNqOqtObBHaJ849P9I65x
nhMitgjBCt5todg7Q5EzjiYKhI89soB27rgPiz4Sr03Bh2WXws30AVE2tBQgKl+N
vbfEAtUnoo58bVl9qTzz1lKUnGBwUM8/JIP/aWnfGFU0h904gPG/OEGPfm5HEqjj
DtqeVjGdHYLbr54s4OWGX5m6m5PExIyCE4WkSwr3RloTyCHYe9MtvZ6DWlZWV0yD
goc0PoOz0iJ642uCV4PDRdlij6tWoAKN6YM0m5sGVE5n4uz1HjoV6NfdgG0Anh2R
n0CbN4oFtRLHXV0wbgghKbjBNzx45+aqgVtr1wIDAQABAoIBAGeMu3B7Ap20fj5P
X8qry43yqz8w9O379evyQZd3hG/19MBuqcFojLDc+Xejv8bnjkeHN2gCTsONhFIc
RiVLAhDMqESGKQO3Eunf4c3RsmZoMcGL71XJB8J0FZY2fA2aWKcSkQuEr2v75VHa
mm7u64vWlq1DpKiivuRqPtevSTWzsP6Y15AC0tpPEI10zGWACUbI96acBbDXu39f
ja6wC8a9ULFQJD2TEzIErLB6o41drqAvVyp4esKeWB3veeWszQ5dzifwGL3hDtEk
G7vdI4ZY3vYb6/cIf5ey4+tI3d7JA5DnAQIL8JWrtrv83UfCGawdDl/sraEfaoSm
ZTSyXxkCgYEA2XYcpNjjwnZq9j3ymkbByMJmmgne6smKki/qjKRFKqHDTWh5cEPA
XKr4GAtmDp8NWhY0lWCkyja31uIz8BEO82YOVsUEAgkEH2IU6lbFhkYtdXClnuzt
kBINNWz0cJe8F1tdpTWEFSa/NlXSrnl0OLW1aS9csXSOR6lx7mJ90qMCgYEAl2hT
LTEWIjQoPBqvQ3DnJf02QdQpa18aGCrcR9+eWniAICNv6CLXNhdy3KdrRwOUQ6+/
Ew9AMknt6xzP4B+kEuEpmVMTbVCwTfOmK031gLX3GHwXMxyMCGTHkgQ7XxfOdg/2
1KOzL5r2Xdz1u+FRP3662muX3Ga9kHVRx28tiT0CgYEAs9Y/vfw37vvrXRTB6uAV
JifOnhkHpvdhh5/kwsafBLCeSQfbVgJRtNEXNxtGHVVfv16ZwecYoLo7spODDEev
K4780LlBpUU7iZCdZ2a3F2I1+edcsF+T3w9uqP4f8HUrcc13Vkc5ohxXCWJUR0Hd
4YA0NHacm4yelZkFxXTiRS0CgYBa8YIMghB+aP/F4m1lv/pHmkmtzsc2RECDRbNc
xJf0Va74HvEH6W2Fgx4uJa3NUPwMkBLgWue/jSKId5zxTXAbGv4Gp5ziq3XKzNAB
8OjG8AXEwjyZKct++zHYpgwXeVA9ICet38owjQ7woFlGCffogLGxorDr5RZ2H9II
TeJ3LQKBgQC+aERTeLY6C3Mq6tgL8yVCZd/058GrFAkalOAKNMlr+G+vKeKupTwH
sJcrrwKHJHpxK9582PslQcLMNcf2fIPJiU1MWtQNh5VixCKFTp9yzrWiu/hMgQn6
QtNwj+n8DaCdMr1fpfQ42c5AGwNUbAZoZ/s3Hql3BnokQ/184wp7uw==
-----END RSA PRIVATE KEY-----
"""
        guard let signedData = sut.sign(signableData.base64EncodedData(), signingKey: incorrectPrivateKey) else {
            XCTFail()
            return
        }
        XCTAssertFalse(verifier.verify(signableData.base64EncodedData(), withSigned: signedData))
    }

}

extension ChallengeSignerTests {
    class ChallengeVerifier {
        
        private let publicKey: SecKey?
        
        init(publicKey: String) {
            //turn base64encoded public key string into SecKey
            guard let keyData = Data(base64Encoded: publicKey) else {
                self.publicKey = nil
                print("pub key is nil")
                return
            }
            let parameters : [String : AnyObject] = [
                kSecAttrKeyType as String : kSecAttrKeyTypeRSA,
                kSecAttrKeyClass as String : kSecAttrKeyClassPublic,
                kSecAttrKeySizeInBits as String : 2048 as AnyObject,
                kSecReturnPersistentRef as String : true as AnyObject
            ]
            if #available(iOS 10.0, *) {
                self.publicKey = SecKeyCreateWithData(keyData as CFData, parameters as CFDictionary, nil)
                print("setting public key")
            } else {
                // Fallback on earlier versions
                print("iOS10 not available, verifying fails")
                self.publicKey = nil
            }
        }
        
        func verify(_ challengeData: Data, withSigned response: Data) -> Bool {
            return verify(challengeData.base64EncodedString(), withSigned: response.base64EncodedString())
        }
        
        func verify(_ base64ChallengeString: String, withSigned response: String) -> Bool {
            guard let challengeData = Data(base64Encoded: base64ChallengeString), let responseData = Data(base64Encoded: response), let publicKey = publicKey else {
                return false
            }
            //hash the message first
            let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
            let hashBytes = UnsafeMutablePointer<UInt8>.allocate(capacity:digestLength)
            CC_SHA256([UInt8](challengeData), CC_LONG(challengeData.count), hashBytes)
            
            //verify
            let status = responseData.withUnsafeBytes { signatureBytes in
                return SecKeyRawVerify(publicKey, .PKCS1SHA256, hashBytes, digestLength, signatureBytes, responseData.count)
            }
            return status == noErr
        }
        
    }

}
