//
//  KeylessError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error object returned from Keyless Client Delegate methods.
public struct KeylessError: Swift.Error {
    ///Populated with StatusDataError objects in the event of an operation failure.
    ///Populated with a single internal error in the event of an SDK level error.
    ///All errors conform to CustomStringConvertable
    public let errors: [Swift.Error]
}
