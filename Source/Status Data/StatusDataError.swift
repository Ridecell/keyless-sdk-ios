//
//  StatusDataError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error object returned within a KeylessError object.
/// Representation of a Status Data message that is sent from the GO9 device to MyGeotab.
public protocol StatusDataError: Swift.Error {
    /// Status Data code from MyGeotab.
    var code: Int { get }
    /// Value associated with Status Data code.
    var value: Int { get }
}
