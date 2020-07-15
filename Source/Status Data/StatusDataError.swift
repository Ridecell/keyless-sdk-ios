//
//  StatusDataError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error object returned within a KeylessError object.
/// Representation of a Status Data message that is sent from the GO9 device to MyGeotab.
public protocol StatusDataError: LocalizedError {
    /// Status Data code from MyGeotab.
    var code: Int { get }
    /// Value associated with Status Data code.
    var value: Int { get }
}

extension StatusDataError {

    public var errorDescription: String? {
        return "\(String(describing: type(of: self))) code: \(code), value: \(value))"
    }
}
