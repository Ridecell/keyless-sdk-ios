//
//  CertificateValidator.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-07.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import Foundation

class CertificateValidator {
    func validate(_ data: Data) -> Bool {

        guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
            log.error("couldn't create cert")
            return false
        }

        var optionalTrust: SecTrust?
        let status = SecTrustCreateWithCertificates(certificate, SecPolicyCreateSSL(true, nil), &optionalTrust)
        guard status == 0, let trust = optionalTrust else {
            log.error("couldn't create trust")
            return false
        }

        var result: SecTrustResultType = .deny
        let resultStatus = SecTrustEvaluate(trust, &result)
        guard resultStatus == 0 else {
            log.error("couldn't evaluate trust")
            return false
        }
        return [.proceed, .unspecified].contains(result)
    }
}
