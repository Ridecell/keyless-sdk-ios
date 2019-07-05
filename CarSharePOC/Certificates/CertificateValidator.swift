//
//  CertificateValidator.swift
//  CarShare
//
//  Created by Matt Snow on 2019-06-07.
//  Copyright © 2019 BSM Technologies Inc. All rights reserved.
//

import Foundation

class CertificateValidator {
    func validate(_ certificate: SecCertificate) -> Bool {
        var optionalTrust: SecTrust?
        let trustStatus = SecTrustCreateWithCertificates(certificate, SecPolicyCreateSSL(true, nil), &optionalTrust)
        guard trustStatus == 0, let trust = optionalTrust else {
            log.error("couldn't create trust")
            return false
        }

        guard let rootCertificate = getRootCertificate() else {
            log.error("couldn't create root certificate")
            return false
        }

        guard SecTrustSetAnchorCertificates(trust, [rootCertificate] as CFArray) == 0 else {
            log.error("Couldn't anchor root")
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

    func validate(_ data: Data) -> Bool {

        guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
            log.error("couldn't create cert")
            return false
        }

        return validate(certificate)
    }

    private func getRootCertificate() -> SecCertificate? {
        guard let filePath = Bundle.main.url(forResource: "matt-root", withExtension: "cer") else {
            return nil
        }
        guard let data = try? Data(contentsOf: filePath) else {
            return nil
        }

        return SecCertificateCreateWithData(nil, data as CFData)
    }
}
