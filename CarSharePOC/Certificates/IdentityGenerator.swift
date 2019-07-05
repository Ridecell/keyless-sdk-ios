//
//  CertificatePutter.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-12.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import Foundation
import Security

class IdentityGenerator {
    func generate(_ pkcs12Data: Data, password: String) throws -> SecIdentity {
        func securityThrower(err: OSStatus) throws {
            if err != errSecSuccess {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(err), userInfo: nil)
            }
        }

        var importResult: CFArray? = nil
        try securityThrower(err: SecPKCS12Import(pkcs12Data as CFData, [
            kSecImportExportPassphrase as String: password
            ] as CFDictionary, &importResult) )
        let dictionaries = importResult! as NSArray as! [[String:AnyObject]]
        let identity = dictionaries.first![kSecImportItemIdentity as String] as! SecIdentity

        return identity
//        let label = NSUUID().uuidString
//        try securityThrower(err: SecItemAdd([
//            kSecAttrLabel as String:    label,
//            kSecValueRef as String:    identity
//            ] as CFDictionary, nil) )
//
//        var copyResult: CFTypeRef? = nil
//        try securityThrower(err: SecItemCopyMatching([
//            kSecClass as String:        kSecClassIdentity,
//            kSecAttrLabel as String:    label,
//            kSecReturnRef as String:    true
//            ] as CFDictionary, &copyResult) )
//        let copiedIdentity = copyResult as! SecIdentity
//
//        return copiedIdentity
    }
}
