//
//  IgnitionInhibitError.swift
//  Keyless
//
//  Created by Marc Maguire on 2020-06-16.
//

import Foundation

/// Error returned when the Ignition Inhibit Operation fails.
public enum IgnitionInhibitError: Int, StatusDataError, CustomStringConvertible {
    /// Failed.
    case attemptedButFailed = 0
    /// Could not queue Ignition Inhibit operation.
    case couldNotQueueOperation = 1

    public var code: Int { return 3_334 }
    public var value: Int { return self.rawValue }

    public var description: String {
        switch self {
        case .attemptedButFailed:
            return "Ignition Inhibit failed due to: Attempted but failed"
        case .couldNotQueueOperation:
            return "Ignition Inhibit failed due to: Could not queue operation"
        }
    }
}
